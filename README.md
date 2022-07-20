# LongReadAnalysis
Pipeline to automate long read analysis 
This pipeline recieves basecalled long read data, concatenates the fastqs, trims of adapters, runs NanoPlot on the reads, and filters the reads.
After filtering, it uses Epi2Me's wf-bacterial-genomes to assemble and annotate the reads. 
