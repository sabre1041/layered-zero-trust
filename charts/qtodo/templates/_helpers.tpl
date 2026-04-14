{{/*
Create the image path for the passed in image field.
When global.registry is enabled with domain and repository, the image
reference is derived from global.registry.domain/repository (e.g.
quay.io/ztvp/qtodo) so no VP --set override is needed.
*/}}
{{- define "qtodo.image" -}}
{{- $name := tpl .value.name .context -}}
{{- $useRegistry := default false .useRegistry -}}
{{- if and $useRegistry .context.Values.global.registry.enabled .context.Values.global.registry.domain .context.Values.global.registry.repository -}}
{{- $name = printf "%s/%s" (tpl .context.Values.global.registry.domain .context) .context.Values.global.registry.repository -}}
{{- end -}}
{{- if eq (substr 0 7 (tpl .value.version .context)) "sha256:" -}}
{{- printf "%s@%s" $name (tpl .value.version .context) -}}
{{- else -}}
{{- printf "%s:%s" $name (tpl .value.version .context) -}}
{{- end -}}
{{- end -}}
