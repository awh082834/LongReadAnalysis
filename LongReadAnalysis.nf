#!/user/bin/env nextflow

nextflow.enable.dsl=2

//Initial task of pipeline
//Run trimming for adapters, put through filtlong, and run fastqc

//input params
params.out
params.in
//params.ref
params.sample

println """\
         L O N G  R E A D  A N A L Y S I S
         =================================
         Input Directory   : ${params.in}
         Output Directory  : ${params.out}
         Sample Name or ID : ${params.sample}
         """
         .stripIndent()
//Channels
reads_ch = Channel.fromPath("${params.in}", checkIfExists: true)

workflow{
  //precprocess and concatenate fastqs
  concatenate(reads_ch)

  //trims adapters
  trim(concatenate.out.concatTrimmed)

  //obtains read metrics
  nanoPlot(trim.out.poreOut)

  //filters concatenated fastq
  filtLong(trim.out.poreOut)

  //assembly
  epi2meAssembly(filtLong.out.filtered)

  //AssemblyQC
  AssemblyQC(epi2meAssembly.out.assembly)
}

process concatenate{
  tag{"Concatenate Fastqs in ${params.in}"}
  label 'process_low'

  publishDir("${params.out}/concated", mode: 'copy')

  input:
  path(reads)

  output:
  path("${params.sample}.fastq.gz"), emit: concatTrimmed

  script:
  """
  cat ${params.in}/*.fastq.gz > ${params.sample}.fastq.gz
  """
}

process trim{
  //run poreChop on multiple files from input
  tag{"PoreChop ${params.in}"}
  label 'process_low'

  publishDir("${params.out}/trimmed", mode: 'copy')

  input:
  path(reads)

  output:
  path("*"), emit: poreOut

  script:
  """
  ~/Porechop/porechop-runner.py  -i ${reads} -o ${params.sample}_trimmed.fastq.gz
  """
}

process nanoPlot{
  tag{"NanoPlot ${params.in}"}
  label 'process_low'

  publishDir("${params.out}", mode: 'copy')

  input:
  path(reads)

  output:
  path("*")

  script:
  """
  NanoPlot --fastq ${reads} --N50 --tsv_stats -o nanoPlotStats
  """
}

process filtLong{
  tag{"FiltLong ${params.in}"}
  label 'process_low'

  publishDir("${params.out}/filtered", mode: 'copy')

  input:
  path(reads)

  output:
  path("${params.sample}_filtered.fastq.gz"), emit: filtered

  script:
  """
  filtlong --keep_percent 95 ${reads} | gzip > ${params.sample}_filtered.fastq.gz
  """
}

process epi2meAssembly{
  tag{"Epi2Me bacterial genome assembly ${params.in}"}
  label 'process_low'

  publishDir("${params.out}", mode: 'copy')

  input:
  path(reads)

  output:
  path("epi2meAssembly/${params.sample}.medaka.fasta.gz"), emit: assembly
  path("epi2meAssembly/*.html")

  script:
  """
  nextflow run epi2me-labs/wf-bacterial-genomes --fastq ${reads} --out_dir epi2meAssembly --sample ${params.sample}
  """
}

process AssemblyQC{
  tag{"QUAST ${params.in}"}
  label 'process_low'

  publishDir("${params.out}", mode: 'copy')

  input:
  path(assembly)

  output:
  path("quastOut/*")

  script:
  """
  quast.py -o quastOut ${assembly}
  """
}
