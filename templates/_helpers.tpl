{{/*
Expand the name of the chart.
*/}}
{{- define "memcached.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "memcached.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "memcached.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "memcached.labels" -}}
helm.sh/chart: {{ include "memcached.chart" . }}
{{ include "memcached.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "memcached.selectorLabels" -}}
app.kubernetes.io/name: {{ include "memcached.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "memcached.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "memcached.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper Memcached image name
*/}}
{{- define "memcached.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
     {{- $registryName = .Values.global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Memcached exporter image name
*/}}
{{- define "memcached.metrics.image" -}}
{{- $registryName := .Values.metrics.image.registry -}}
{{- $repositoryName := .Values.metrics.image.repository -}}
{{- $tag := .Values.metrics.image.tag | toString -}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
     {{- $registryName = .Values.global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "memcached.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- if .Values.global }}
  {{- range .Values.global.imagePullSecrets -}}
    {{- $pullSecrets = append $pullSecrets . -}}
  {{- end -}}
{{- end -}}
{{- range .Values.image.pullSecrets -}}
  {{- $pullSecrets = append $pullSecrets . -}}
{{- end -}}
{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
{{- range $pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return true if a secret object should be created
*/}}
{{- define "memcached.createSecret" -}}
{{- if and .Values.auth.enabled (not .Values.auth.existingSecret) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the Memcached secret name
*/}}
{{- define "memcached.secretName" -}}
{{- if .Values.auth.existingSecret }}
    {{- .Values.auth.existingSecret -}}
{{- else -}}
    {{- include "memcached.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "memcached.validateValues" -}}
{{- $messages := list -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{- printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Return a soft podAffinity/podAntiAffinity definition
*/}}
{{- define "memcached.affinities.pods" -}}
{{- $type := .type -}}
{{- $context := .context -}}
{{- if eq $type "soft" }}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    podAffinityTerm:
      labelSelector:
        matchLabels: {{- include "memcached.selectorLabels" $context | nindent 10 }}
      topologyKey: kubernetes.io/hostname
{{- else if eq $type "hard" }}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- include "memcached.selectorLabels" $context | nindent 8 }}
    topologyKey: kubernetes.io/hostname
{{- end -}}
{{- end -}}

{{/*
Return a nodeAffinity definition
*/}}
{{- define "memcached.affinities.nodes" -}}
{{- $type := .type -}}
{{- $key := .key -}}
{{- $values := .values -}}
{{- if eq $type "soft" }}
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 1
    preference:
      matchExpressions:
        - key: {{ $key }}
          operator: In
          values:
          {{- range $values }}
            - {{ . | quote }}
          {{- end }}
{{- else if eq $type "hard" }}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ $key }}
          operator: In
          values:
          {{- range $values }}
            - {{ . | quote }}
          {{- end }}
{{- end -}}
{{- end -}}

{{/*
========================================
Memcached Configuration Helpers
========================================
These helpers automatically configure Memcached's extstore feature
when persistence is enabled, simplifying the StatefulSet definition.
*/}}

{{/*
Calculate the extstore size from persistence size
Returns the storage size as 90% of the persistence volume to allow for filesystem overhead
Supports both Gi and G suffixes
Example: 50Gi -> 45, 100G -> 90
*/}}
{{- define "memcached.extstore.size" -}}
{{- if .Values.persistence.enabled -}}
{{- $size := .Values.persistence.size -}}
{{- $sizeValue := 0 -}}
{{- if hasSuffix "Gi" $size -}}
  {{- $sizeValue = trimSuffix "Gi" $size | int -}}
{{- else if hasSuffix "G" $size -}}
  {{- $sizeValue = trimSuffix "G" $size | int -}}
{{- else -}}
  {{- fail "persistence.size must end with 'Gi' or 'G'" -}}
{{- end -}}
{{- $calculatedSize := div (mul $sizeValue 9) 10 -}}
{{- printf "%d" $calculatedSize -}}
{{- end -}}
{{- end -}}

{{/*
Build the complete extended options string for Memcached
Combines extendedOptions, extraExtendedOptions, and automatic extstore configuration
Returns: "modern,track_sizes,ext_path=/data/extstore:45G,ext_wbuf_size=16"
*/}}
{{- define "memcached.extendedOptions" -}}
{{- $options := list .Values.memcached.extendedOptions -}}
{{- if .Values.memcached.extraExtendedOptions -}}
  {{- $options = append $options .Values.memcached.extraExtendedOptions -}}
{{- end -}}
{{- if .Values.persistence.enabled -}}
  {{- $extstoreSize := include "memcached.extstore.size" . -}}
  {{- $extstorePath := printf "ext_path=%s/extstore:%sG" .Values.persistence.mountPath $extstoreSize -}}
  {{- $options = append $options $extstorePath -}}
  {{- if not (contains "ext_wbuf_size" .Values.memcached.extraExtendedOptions) -}}
    {{- $options = append $options "ext_wbuf_size=16" -}}
  {{- end -}}
{{- end -}}
{{- join "," $options -}}
{{- end -}}

{{/*
Build the memcached command arguments
Returns the complete args array for the memcached container
*/}}
{{- define "memcached.args" -}}
- -m
- {{ .Values.memcached.allocatedMemory | quote }}
- --extended={{ include "memcached.extendedOptions" . }}
- -I
- {{ .Values.memcached.maxItemMemory }}m
- -c
- {{ .Values.memcached.connectionLimit | quote }}
{{- if .Values.memcached.verbosity }}
- -{{ .Values.memcached.verbosity }}
{{- end }}
- -p
- {{ .Values.memcached.port | quote }}
{{- if .Values.auth.enabled }}
- -S
{{- end }}
{{- range $index, $arg := .Values.extraArgs }}
- "-{{ $arg.key }}{{ if $arg.value }} {{ $arg.value }}{{ end }}"
{{- end }}
{{- end -}}
