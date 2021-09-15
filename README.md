## *SVsig* - Recurrent structural variations detection in cancer whole genomes

Description
-----------
SVsig is a method developed to classify rearrangements as passenger or driver in cancer patient cohort of whole genome sequences. The distribution of rearrangements in the cancer genome is shaped by both the mechanisms of their formation and the fitness advantages they confer on the cell. This analysis revealed significant predictors of the distribution of rearrangement across the genome and identified known and novel rearrangements that recurred more often than expected given these predictions (for more detailed description: https://doi.org/10.1101/187609)

#Input
Tab-delimited file with merged SV titled 'tracks/merged_1.6.1.csv' with the following columns:
seqnames, start, strand1, altchr, altpos, strand2, subtype(histology), sv_id, sid(sample ID), donor_unique_id
