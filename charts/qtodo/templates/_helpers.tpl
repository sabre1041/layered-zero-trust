{{/*
Create the image path for the passed in image field
*/}}
{{- define "qtodo.image" -}}
{{- if eq (substr 0 7 (tpl .value.version .context)) "sha256:" -}}
{{- printf "%s@%s" (tpl .value.name .context) (tpl .value.version .context) -}}
{{- else -}}
{{- printf "%s:%s" (tpl .value.name .context) (tpl .value.version .context) -}}
{{- end -}}
{{- end -}}
