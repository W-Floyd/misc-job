package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/kelseyhightower/envconfig"
	"gopkg.in/yaml.v3"
)

var (
	configData  map[string]interface{} = make(map[string]interface{})
	secretsData map[string]interface{} = make(map[string]interface{})
)

type Specification struct {
	TemplateDir   string   `default:"./data/templates"`
	TargetDir     string   `default:"./data/targets"`
	ConfigDir     string   `default:"./data/configs"`
	SecretsDir    string   `default:"./data/secrets"`
	OutputDir     string   `default:"./output"`
	PrintToStdout bool     `default:"true" split_words:"true"`
	ProcessList   []string `split_words:"true"`
}

func main() {

	var s Specification

	err := envconfig.Process("builder", &s)
	if err != nil {
		log.Fatalln(err)
	}

	// Add custom template functions here
	funcs := template.FuncMap{
		// `join` is used like so:
		//		{{ join $entries ", " }}
		// So that you can join a list with a specified separator
		"join": func(elems []interface{}, sep string) string {
			vals := []string{}
			for _, val := range elems {
				vals = append(vals, val.(string))
			}
			return strings.Join(vals, sep)
		},
		// `v` is used like so:
		// 		{{ v "key.path.like.so" }}
		// So that you can access nested values easily - uses a flattened YAML tree
		"v": func(e interface{}) string {
			v := configData[e.(string)]
			return v.(string)
		},
		// `vbool` is used like so:
		//		{{ if vbool "key.path.like.so" }}
		//			...
		//		{{ end }}
		"vbool": func(e interface{}) (ret bool, err error) {
			v, ok := configData[e.(string)]
			if !ok {
				err = fmt.Errorf("Key " + e.(string) + " does not exist")
			}
			ret = v.(bool)
			return
		},
		"inc": func(i int) int {
			return i + 1
		},
		"dec": func(i int) int {
			return i - 1
		},
		"vbar": func() string {
			if configData["debug"].(bool) {
				return "|"
			}
			return ""
		},
		"hline": func() string {
			if configData["debug"].(bool) {
				return `\hline`
			}
			return ""
		},
	}

	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.LUTC | log.Lshortfile)

	templates := template.New("master").Funcs(funcs)

	err = filepath.Walk(s.TemplateDir, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			fileContents, err := os.ReadFile(path)
			if err != nil {
				log.Fatalln(err)
			}

			templateString := "{{ define \"" + strings.TrimPrefix(path, strings.TrimPrefix(s.TemplateDir, "./")+"/") + "\" }}" + string(fileContents) + "{{ end }}"

			_, err = templates.Parse(templateString)
			if err != nil {
				log.Println(err)
				log.Fatalln(templateString)
			}
		}
		return err
	})
	if err != nil {
		log.Fatalln(err)
	}

	err = filepath.Walk(s.ConfigDir, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			t, err := templates.Clone()
			if err != nil {
				log.Fatalln(err)
			}

			fileContents, err := os.ReadFile(path)
			if err != nil {
				log.Fatalln(err)
			}

			t.Parse(string(fileContents))

			buf := new(bytes.Buffer)

			t.Execute(buf, "")

			config := buf.Bytes()

			yamlData := map[string]interface{}{}

			err = yaml.Unmarshal(config, &yamlData)
			if err != nil {
				return err
			}

			configData = Flatten(yamlData)

			if !yamlData["process"].(bool) {
				return nil
			}

			outputList := make(map[string]bool)

			shouldProcessAll := true

			if len(os.Args[1:]) > 0 {
				for _, arg := range os.Args[1:] {
					outputList[arg] = true
				}
			} else if len(s.ProcessList) > 0 {
				for _, arg := range s.ProcessList {
					outputList[arg] = true
				}
			}

			if len(outputList) > 0 {
				shouldProcessAll = false
			}

			loadedSecrets := false

			for _, output := range yamlData["output"].([]interface{}) {

				outputTarget := output.(map[string]interface{})["target"].(string)
				outputName := output.(map[string]interface{})["name"].(string)

				shouldProcess := false

				if shouldProcessAll || outputList[outputName] {
					shouldProcess = true
				}

				if !shouldProcess {
					continue
				}

				if !loadedSecrets {
					if secretsFilename, ok := yamlData["secrets"]; ok {
						secretsFileContents, err := os.ReadFile(s.SecretsDir + "/" + secretsFilename.(string))
						if err != nil {
							return err
						}
						secretsDataRaw := map[string]interface{}{}
						err = yaml.Unmarshal(secretsFileContents, &secretsDataRaw)
						if err != nil {
							return err
						}
						yamlData = mergeMaps(secretsDataRaw, yamlData)
						secretsData = Flatten(secretsDataRaw)
						configData = mergeMaps(secretsData, configData)
					}
				}
				loadedSecrets = true

				targetPath := s.TargetDir + "/" + outputTarget
				if err != nil {
					log.Println(err)
					continue
				}

				if outputTarget == "" {
					return fmt.Errorf(targetPath + " is incorrect")
				}

				fileContents, err = os.ReadFile(targetPath)
				if err != nil {
					log.Println(err)
					continue
				}

				_, err = t.Parse(string(fileContents))
				if err != nil {
					log.Println(err)
					continue
				}

				f, err := os.Create(s.OutputDir + "/" + outputName + filepath.Ext(targetPath))

				if err != nil {
					log.Println(err)
					continue
				}

				defer func() {
					err := f.Close()
					if err != nil {
						log.Println(err)
					}
				}()

				var pipe io.Writer
				if s.PrintToStdout {
					pipe = io.MultiWriter(os.Stdout, f)
				} else {
					pipe = f
				}

				err = t.Execute(pipe, yamlData)
				if err != nil {
					log.Println(err)
					continue
				}

			}

		}
		return err
	})
	if err != nil {
		log.Fatalln(err)
	}

}

func Flatten(m map[string]interface{}) map[string]interface{} {
	o := make(map[string]interface{})
	for k, v := range m {
		switch child := v.(type) {
		case map[string]interface{}:
			nm := Flatten(child)
			for nk, nv := range nm {
				o[k+"."+nk] = nv
			}
		default:
			o[k] = v
		}
	}
	return o
}

// overwriting duplicate keys, you should handle that if there is a need
func mergeMaps(maps ...map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})
	for _, m := range maps {
		for k, v := range m {
			result[k] = v
		}
	}
	return result
}
