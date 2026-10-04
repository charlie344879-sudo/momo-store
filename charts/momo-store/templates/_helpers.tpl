{{- define "momo.labels" -}}
app.kubernetes.io/part-of: momo-store
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "momo.pullSecrets" -}}
{{- if .Values.imageCredentials.enabled }}
imagePullSecrets:
  - name: {{ .Release.Name }}-regcred
{{- end }}
{{- end }}
