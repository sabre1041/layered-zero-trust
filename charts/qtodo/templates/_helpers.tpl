{{/*
Create the image path for the passed in image field
*/}}
{{- define "qtodo.image" -}}
{{- if eq (substr 0 7 .version) "sha256:" -}}
{{- printf "%s@%s" (tpl .name .) (tpl .version .) -}}
{{- else -}}
{{- printf "%s:%s" (tpl .name .) (tpl .version .) -}}
{{- end -}}
{{- end -}}
