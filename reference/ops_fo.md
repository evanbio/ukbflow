# First Occurrence health outcome fields (offline lookup)

UK Biobank derives a "First Occurrence" field for each of ~1,165 health
outcomes defined at the 3-character ICD-10 level (chapters I-XVII,
excluding the cancer chapter, which is covered by the cancer registry).
Each outcome has a *date* field – the earliest date the condition was
recorded across self-report, primary care, hospital inpatient, and death
data – and a paired *source* field naming which of those the earliest
record came from. This is an offline catalogue mapping each outcome's
ICD-10 code and name to its date and source field IDs, so the right
field can be found without searching the Showcase; the date field feeds
straight into
[`derive_first_occurrence`](https://evanbio.github.io/ukbflow/reference/derive_first_occurrence.md).

## Usage

``` r
ops_fo(pattern = NULL, chapter = NULL)
```

## Arguments

- pattern:

  (character or NULL) Optional case-insensitive keyword or regular
  expression filtered across the `icd10` code, `name`, and the
  `date_field` / `source_field` IDs. A code stem such as `"I2"` matches
  every code beginning I2 (I20-I29); a field ID does a reverse lookup.
  Default `NULL` returns all outcomes.

- chapter:

  (character or NULL) Optional case-insensitive keyword matched against
  the `chapter` column, e.g. `"circulatory"`.

## Value

A `data.table` with columns:

- icd10:

  3-character ICD-10 code.

- name:

  Outcome name.

- chapter:

  ICD-10 chapter the outcome belongs to.

- date_field:

  Integer field ID of the first-occurrence date.

- source_field:

  Integer field ID of the paired source-of-report.

## Details

The underlying code lists are UK Biobank's own algorithmic mapping and
have not been clinically reviewed or externally validated; treat a First
Occurrence outcome as a first pass at identifying cases.

The full table is always returned; `pattern` and `chapter` only subset
it. Console output reports what came back – one line per chapter for an
unfiltered call, a single line otherwise.

## Examples

``` r
ops_fo()
#> 
#> ── ukbflow first occurrence outcomes ───────────────────────────────────────────
#> Certain infectious and parasitic diseases: 173
#> Blood, blood-forming organs and certain immune disorders: 34
#> Endocrine, nutritional and metabolic diseases: 73
#> Mental and behavioural disorders: 78
#> Nervous system disorders: 68
#> Eye and adnexa disorders: 47
#> Ear and mastoid process disorders: 24
#> Circulatory system disorders: 77
#> Respiratory system disorders: 64
#> Digestive system disorders: 72
#> Skin and subcutaneous tissue disorders: 72
#> Musculoskeletal system and connective tissue disorders: 79
#> Genitourinary system disorders: 82
#> Pregnancy, childbirth and the puerperium: 76
#> Certain conditions originating in the perinatal period: 59
#> Congenital disruptions and chromosomal abnormalities: 87
#> total: 1165
#>        icd10
#>       <char>
#>    1:    A00
#>    2:    A01
#>    3:    A02
#>    4:    A03
#>    5:    A04
#>   ---       
#> 1161:    Q95
#> 1162:    Q96
#> 1163:    Q97
#> 1164:    Q98
#> 1165:    Q99
#>                                                                                 name
#>                                                                               <char>
#>    1:                                                                        cholera
#>    2:                                                 typhoid and paratyphoid fevers
#>    3:                                                    other salmonella infections
#>    4:                                                                    shigellosis
#>    5:                                          other bacterial intestinal infections
#>   ---                                                                               
#> 1161:       balanced rearrangements and structural markers, not elsewhere classified
#> 1162:                                                              turner's syndrome
#> 1163: other sex chromosome abnormalities, female phenotype, not elsewhere classified
#> 1164:   other sex chromosome abnormalities, male phenotype, not elsewhere classified
#> 1165:                       other chromosome abnormalities, not elsewhere classified
#>                                                    chapter date_field
#>                                                     <char>      <int>
#>    1:            Certain infectious and parasitic diseases     130000
#>    2:            Certain infectious and parasitic diseases     130002
#>    3:            Certain infectious and parasitic diseases     130004
#>    4:            Certain infectious and parasitic diseases     130006
#>    5:            Certain infectious and parasitic diseases     130008
#>   ---                                                                
#> 1161: Congenital disruptions and chromosomal abnormalities     132596
#> 1162: Congenital disruptions and chromosomal abnormalities     132598
#> 1163: Congenital disruptions and chromosomal abnormalities     132600
#> 1164: Congenital disruptions and chromosomal abnormalities     132602
#> 1165: Congenital disruptions and chromosomal abnormalities     132604
#>       source_field
#>              <int>
#>    1:       130001
#>    2:       130003
#>    3:       130005
#>    4:       130007
#>    5:       130009
#>   ---             
#> 1161:       132597
#> 1162:       132599
#> 1163:       132601
#> 1164:       132603
#> 1165:       132605
ops_fo("I21")
#> ✔ ops_fo: 1 outcome matching "I21".
#>     icd10                        name                      chapter date_field
#>    <char>                      <char>                       <char>      <int>
#> 1:    I21 acute myocardial infarction Circulatory system disorders     131298
#>    source_field
#>           <int>
#> 1:       131299
ops_fo("myocardial")
#> ✔ ops_fo: 3 outcomes matching "myocardial".
#>     icd10                                                                name
#>    <char>                                                              <char>
#> 1:    I21                                         acute myocardial infarction
#> 2:    I22                                    subsequent myocardial infarction
#> 3:    I23 certain current complications following acute myocardial infarction
#>                         chapter date_field source_field
#>                          <char>      <int>        <int>
#> 1: Circulatory system disorders     131298       131299
#> 2: Circulatory system disorders     131300       131301
#> 3: Circulatory system disorders     131302       131303
ops_fo("I2")                       # every I2x code
#> ✔ ops_fo: 9 outcomes matching "I2".
#>     icd10                                                                name
#>    <char>                                                              <char>
#> 1:    I20                                                     angina pectoris
#> 2:    I21                                         acute myocardial infarction
#> 3:    I22                                    subsequent myocardial infarction
#> 4:    I23 certain current complications following acute myocardial infarction
#> 5:    I24                                other acute ischaemic heart diseases
#> 6:    I25                                     chronic ischaemic heart disease
#> 7:    I26                                                  pulmonary embolism
#> 8:    I27                                      other pulmonary heart diseases
#> 9:    I28                                 other diseases of pulmonary vessels
#>                         chapter date_field source_field
#>                          <char>      <int>        <int>
#> 1: Circulatory system disorders     131296       131297
#> 2: Circulatory system disorders     131298       131299
#> 3: Circulatory system disorders     131300       131301
#> 4: Circulatory system disorders     131302       131303
#> 5: Circulatory system disorders     131304       131305
#> 6: Circulatory system disorders     131306       131307
#> 7: Circulatory system disorders     131308       131309
#> 8: Circulatory system disorders     131310       131311
#> 9: Circulatory system disorders     131312       131313
ops_fo(chapter = "circulatory")
#> ✔ ops_fo: 77 outcomes in chapter "circulatory".
#>      icd10
#>     <char>
#>  1:    I00
#>  2:    I01
#>  3:    I02
#>  4:    I05
#>  5:    I06
#>  6:    I07
#>  7:    I08
#>  8:    I09
#>  9:    I10
#> 10:    I11
#> 11:    I12
#> 12:    I13
#> 13:    I15
#> 14:    I20
#> 15:    I21
#> 16:    I22
#> 17:    I23
#> 18:    I24
#> 19:    I25
#> 20:    I26
#> 21:    I27
#> 22:    I28
#> 23:    I30
#> 24:    I31
#> 25:    I32
#> 26:    I33
#> 27:    I34
#> 28:    I35
#> 29:    I36
#> 30:    I37
#> 31:    I38
#> 32:    I39
#> 33:    I40
#> 34:    I41
#> 35:    I42
#> 36:    I43
#> 37:    I44
#> 38:    I45
#> 39:    I46
#> 40:    I47
#> 41:    I48
#> 42:    I49
#> 43:    I50
#> 44:    I51
#> 45:    I52
#> 46:    I60
#> 47:    I61
#> 48:    I62
#> 49:    I63
#> 50:    I64
#> 51:    I65
#> 52:    I66
#> 53:    I67
#> 54:    I68
#> 55:    I69
#> 56:    I70
#> 57:    I71
#> 58:    I72
#> 59:    I73
#> 60:    I74
#> 61:    I77
#> 62:    I78
#> 63:    I79
#> 64:    I80
#> 65:    I81
#> 66:    I82
#> 67:    I83
#> 68:    I84
#> 69:    I85
#> 70:    I86
#> 71:    I87
#> 72:    I88
#> 73:    I89
#> 74:    I95
#> 75:    I97
#> 76:    I98
#> 77:    I99
#>      icd10
#>     <char>
#>                                                                                     name
#>                                                                                   <char>
#>  1:                                 rheumatic fever without mention of heart involvement
#>  2:                                               rheumatic fever with heart involvement
#>  3:                                                                     rheumatic chorea
#>  4:                                                      rheumatic mitral valve diseases
#>  5:                                                      rheumatic aortic valve diseases
#>  6:                                                   rheumatic tricuspid valve diseases
#>  7:                                                              multiple valve diseases
#>  8:                                                       other rheumatic heart diseases
#>  9:                                                     essential (primary) hypertension
#> 10:                                                           hypertensive heart disease
#> 11:                                                           hypertensive renal disease
#> 12:                                                 hypertensive heart and renal disease
#> 13:                                                               secondary hypertension
#> 14:                                                                      angina pectoris
#> 15:                                                          acute myocardial infarction
#> 16:                                                     subsequent myocardial infarction
#> 17:                  certain current complications following acute myocardial infarction
#> 18:                                                 other acute ischaemic heart diseases
#> 19:                                                      chronic ischaemic heart disease
#> 20:                                                                   pulmonary embolism
#> 21:                                                       other pulmonary heart diseases
#> 22:                                                  other diseases of pulmonary vessels
#> 23:                                                                   acute pericarditis
#> 24:                                                        other diseases of pericardium
#> 25:                                        pericarditis in diseases classified elsewhere
#> 26:                                                      acute and subacute endocarditis
#> 27:                                                  nonrheumatic mitral valve disorders
#> 28:                                                  nonrheumatic aortic valve disorders
#> 29:                                               nonrheumatic tricuspid valve disorders
#> 30:                                                            pulmonary valve disorders
#> 31:                                                      endocarditis, valve unspecified
#> 32:              endocarditis and heart valve disorders in diseases classified elsewhere
#> 33:                                                                    acute myocarditis
#> 34:                                         myocarditis in diseases classified elsewhere
#> 35:                                                                       cardiomyopathy
#> 36:                                      cardiomyopathy in diseases classified elsewhere
#> 37:                                        atrioventricular and left bundle-branch block
#> 38:                                                           other conduction disorders
#> 39:                                                                       cardiac arrest
#> 40:                                                               paroxysmal tachycardia
#> 41:                                                      atrial fibrillation and flutter
#> 42:                                                            other cardiac arrhythmias
#> 43:                                                                        heart failure
#> 44:                          complications and ill-defined descriptions of heart disease
#> 45:                               other heart disorders in diseases classified elsewhere
#> 46:                                                             subarachnoid haemorrhage
#> 47:                                                            intracerebral haemorrhage
#> 48:                                          other nontraumatic intracranial haemorrhage
#> 49:                                                                  cerebral infarction
#> 50:                                   stroke, not specified as haemorrhage or infarction
#> 51: occlusion and stenosis of precerebral arteries, not resulting in cerebral infarction
#> 52:    occlusion and stenosis of cerebral arteries, not resulting in cerebral infarction
#> 53:                                                       other cerebrovascular diseases
#> 54:                           cerebrovascular disorders in diseases classified elsewhere
#> 55:                                                  sequelae of cerebrovascular disease
#> 56:                                                                      atherosclerosis
#> 57:                                                       aortic aneurysm and dissection
#> 58:                                                                       other aneurysm
#> 59:                                                   other peripheral vascular diseases
#> 60:                                                     arterial embolism and thrombosis
#> 61:                                           other disorders of arteries and arterioles
#> 62:                                                              diseases of capillaries
#> 63:   disorders of arteries, arterioles and capillaries in diseases classified elsewhere
#> 64:                                                       phlebitis and thrombophlebitis
#> 65:                                                               portal vein thrombosis
#> 66:                                                 other venous embolism and thrombosis
#> 67:                                                  varicose veins of lower extremities
#> 68:                                                                         haemorrhoids
#> 69:                                                                  oesophageal varices
#> 70:                                                        varicose veins of other sites
#> 71:                                                             other disorders of veins
#> 72:                                                            nonspecific lymphadenitis
#> 73:                   other non-infective disorders of lymphatic vessels and lymph nodes
#> 74:                                                                          hypotension
#> 75:             postprocedural disorders of circulatory system, not elsewhere classified
#> 76:               other disorders of circulatory system in diseases classified elsewhere
#> 77:                                other and unspecified disorders of circulatory system
#>                                                                                     name
#>                                                                                   <char>
#>                          chapter date_field source_field
#>                           <char>      <int>        <int>
#>  1: Circulatory system disorders     131270       131271
#>  2: Circulatory system disorders     131272       131273
#>  3: Circulatory system disorders     131274       131275
#>  4: Circulatory system disorders     131276       131277
#>  5: Circulatory system disorders     131278       131279
#>  6: Circulatory system disorders     131280       131281
#>  7: Circulatory system disorders     131282       131283
#>  8: Circulatory system disorders     131284       131285
#>  9: Circulatory system disorders     131286       131287
#> 10: Circulatory system disorders     131288       131289
#> 11: Circulatory system disorders     131290       131291
#> 12: Circulatory system disorders     131292       131293
#> 13: Circulatory system disorders     131294       131295
#> 14: Circulatory system disorders     131296       131297
#> 15: Circulatory system disorders     131298       131299
#> 16: Circulatory system disorders     131300       131301
#> 17: Circulatory system disorders     131302       131303
#> 18: Circulatory system disorders     131304       131305
#> 19: Circulatory system disorders     131306       131307
#> 20: Circulatory system disorders     131308       131309
#> 21: Circulatory system disorders     131310       131311
#> 22: Circulatory system disorders     131312       131313
#> 23: Circulatory system disorders     131314       131315
#> 24: Circulatory system disorders     131316       131317
#> 25: Circulatory system disorders     131318       131319
#> 26: Circulatory system disorders     131320       131321
#> 27: Circulatory system disorders     131322       131323
#> 28: Circulatory system disorders     131324       131325
#> 29: Circulatory system disorders     131326       131327
#> 30: Circulatory system disorders     131328       131329
#> 31: Circulatory system disorders     131330       131331
#> 32: Circulatory system disorders     131332       131333
#> 33: Circulatory system disorders     131334       131335
#> 34: Circulatory system disorders     131336       131337
#> 35: Circulatory system disorders     131338       131339
#> 36: Circulatory system disorders     131340       131341
#> 37: Circulatory system disorders     131342       131343
#> 38: Circulatory system disorders     131344       131345
#> 39: Circulatory system disorders     131346       131347
#> 40: Circulatory system disorders     131348       131349
#> 41: Circulatory system disorders     131350       131351
#> 42: Circulatory system disorders     131352       131353
#> 43: Circulatory system disorders     131354       131355
#> 44: Circulatory system disorders     131356       131357
#> 45: Circulatory system disorders     131358       131359
#> 46: Circulatory system disorders     131360       131361
#> 47: Circulatory system disorders     131362       131363
#> 48: Circulatory system disorders     131364       131365
#> 49: Circulatory system disorders     131366       131367
#> 50: Circulatory system disorders     131368       131369
#> 51: Circulatory system disorders     131370       131371
#> 52: Circulatory system disorders     131372       131373
#> 53: Circulatory system disorders     131374       131375
#> 54: Circulatory system disorders     131376       131377
#> 55: Circulatory system disorders     131378       131379
#> 56: Circulatory system disorders     131380       131381
#> 57: Circulatory system disorders     131382       131383
#> 58: Circulatory system disorders     131384       131385
#> 59: Circulatory system disorders     131386       131387
#> 60: Circulatory system disorders     131388       131389
#> 61: Circulatory system disorders     131390       131391
#> 62: Circulatory system disorders     131392       131393
#> 63: Circulatory system disorders     131394       131395
#> 64: Circulatory system disorders     131396       131397
#> 65: Circulatory system disorders     131398       131399
#> 66: Circulatory system disorders     131400       131401
#> 67: Circulatory system disorders     131402       131403
#> 68: Circulatory system disorders     131404       131405
#> 69: Circulatory system disorders     131406       131407
#> 70: Circulatory system disorders     131408       131409
#> 71: Circulatory system disorders     131410       131411
#> 72: Circulatory system disorders     131412       131413
#> 73: Circulatory system disorders     131414       131415
#> 74: Circulatory system disorders     131416       131417
#> 75: Circulatory system disorders     131418       131419
#> 76: Circulatory system disorders     131420       131421
#> 77: Circulatory system disorders     131422       131423
#>                          chapter date_field source_field
#>                           <char>      <int>        <int>
```
