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

var configData map[string]interface{} = make(map[string]interface{})

type Specification struct {
	TemplateDir   string `default:"./data/templates"`
	TargetDir     string `default:"./data/targets"`
	ConfigDir     string `default:"./data/configs"`
	OutputDir     string `default:"./output"`
	PrintToStdout bool   `default:"true" split_words:"true"`
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
	}

	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.LUTC | log.Lshortfile)

	templates := template.New("master").Funcs(funcs)

	err = filepath.Walk(s.TemplateDir, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			fileContents, err := os.ReadFile(path)
			if err != nil {
				log.Fatalln(err)
			}
			_, err = templates.Parse("{{ define \"" + strings.TrimPrefix(path, strings.TrimPrefix(s.TemplateDir, "./")+"/") + "\" }}" + string(fileContents) + "{{end}}")
			if err != nil {
				log.Fatalln(err)
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
				log.Fatal(err)
			}

			if !yamlData["process"].(bool) {
				return nil
			}

			targetPath := s.TargetDir + "/" + yamlData["target"].(string)
			if err != nil {
				log.Fatalln(err)
			}

			if yamlData["target"].(string) == "" {
				return fmt.Errorf(targetPath + " is incorrect")
			}

			fileContents, err = os.ReadFile(targetPath)
			if err != nil {
				log.Fatalln(err)
			}

			t.Parse(string(fileContents))

			f, err := os.Create(s.OutputDir + "/" + yamlData["output_name"].(string) + filepath.Ext(targetPath))
			if err != nil {
				log.Fatalln(err)
			}

			configData = Flatten(yamlData)

			var pipe io.Writer
			if s.PrintToStdout {
				pipe = io.MultiWriter(os.Stdout, f)
			} else {
				pipe = f
			}

			t.Execute(pipe, yamlData)

			f.Close()

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
