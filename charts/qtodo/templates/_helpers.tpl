{{/*
Create the image path for the passed in image field.
For the main app image (isMain=true), when global.registry is enabled the
name is derived from global.registry.domain/org so no values-hub override
is needed (VP overrides don't support template expressions).
*/}}
{{- define "qtodo.image" -}}
{{- $name := tpl .value.name .context -}}
{{- if and (.isMain) .context.Values.global.registry.enabled .context.Values.global.registry.domain .context.Values.global.registry.org -}}
{{- $name = printf "%s/%s/qtodo" (tpl .context.Values.global.registry.domain .context) .context.Values.global.registry.org -}}
{{- end -}}
{{- if eq (substr 0 7 (tpl .value.version .context)) "sha256:" -}}
{{- printf "%s@%s" $name (tpl .value.version .context) -}}
{{- else -}}
{{- printf "%s:%s" $name (tpl .value.version .context) -}}
{{- end -}}
{{- end -}}
