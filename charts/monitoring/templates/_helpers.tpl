{{- define "mon.labels" -}}
app.kubernetes.io/part-of: momo-monitoring
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
