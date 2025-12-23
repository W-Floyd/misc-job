# Resume and CV Templating

Borrowing the core templating idea from [Davide Pucci's 'erro'](https://davidepucci.it/doc/erro/), I have used the Golang text/template engine to build a system for my needs. The LaTeX document is a highly modified version of an old copy of his personal template. It uses [tectonic](https://github.com/tectonic-typesetting/tectonic) which is a lovely LaTeX engine.

To build, assuming you have docker compose, you can run `docker compose run --build builder` (`--build` is optional if you're not changing the Go code).
To build specific `output_name`s, you can simply list them after the above command.
For example, if the `output_name` is `William Floyd`, you would run:
`docker compose run --build builder 'William Floyd'`

## See also

- [rendercv](https://github.com/rendercv/rendercv) - I'd probably use this if I hadn't already made this already
