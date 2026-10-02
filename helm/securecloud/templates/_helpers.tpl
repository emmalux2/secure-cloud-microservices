{{- define "securecloud.fullname" -}}
{{- .Release.Name | trunc 42 | trimSuffix "-" -}}
{{- end -}}