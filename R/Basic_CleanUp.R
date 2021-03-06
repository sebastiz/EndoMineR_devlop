if (getRversion() >= "2.15.1")
  utils::globalVariables(
    c(
      "PatientID",
      ".SD",
      "CStage",
      "NumbOfBx",
      "Years",
      "Difference",
      "barplot",
      "head",
      "read.table",
      "eHospitalNum",
      "pHospitalNum",
      ".",
      "EVENT",
      "MonthYear",
      "freq",
      "Endoscopist",
      "avg",
      "v",
      "destination",
      "dcast",
      "complete.cases",
      "g",
      "gvisSankey",
      "head",
      "pHospitalNum",
      "par",
      "plot",
      "r",
      "read.table",
      "region",
      "rgb",
      "setDT",
      "Myendo",
      "Mypath",
      "doc_id",
      "sentence",
      "upos",
      "xpos",
      "feats",
      "udmodel_english",
      "cbind_dependencies",
      "head_token_id",
      "deps",
      "morph_voice",
      "OriginalReport",
      "dep_rel",
      "misc",
      "has_morph",
      "morph_abbr",
      "morph_case",
      "morph_definite",
      "morph_degree",
      "morph_foreign",
      "morph_gender",
      "morph_mood",
      "morph_number",
      "morph_numtype",
      "morph_person",
      "morph_poss",
      "morph_prontype",
      "morph_reflex",
      "morph_tense",
      "morph_verbform",
      "str_subset",
      "lower",
      "upper",
      "pathSiteString",
      "outputFinal",
      "theme_foundation",
      "udmodel",
      "x3",
      "FINDINGSmyDx",
      "FindingsAfterProcessing",
      "primDxVector",
      "Temporal",
      "sentence_id"
    )
  )











##########Text preparation##########



#' textPrep function
#'
#' This function prepares the data by cleaning 
#' punctuation, checking spelling against the lexicons, mapping terms
#' accorsing to the lexicons, removing negative expressions
#' and lower casing everything. It contains several of the other functions
#' in the package for ease of use. The user can decide whether to also include
#' POS tagging and Negative removal as well as which extractor. By default the
#' extractor called 'Extractor' (which assumes all headers are present in the
#' same order in each text entry) is used. Also by default the negative phrases
#' are removed and POS tagging is not performed.
#' @keywords Find and replace
#' @param inputText The relevant pathology text column
#' @param delim the delimitors so the extractor can be used
#' @param NegEx parameter to say whether the NegativeRemove function used.
#' @param Extractor this states which Extractor you want to use. 1 is 
#' Extractor 1 (for uniformly ordered headers), 2 is Extractor2 for
#' text when headers are sometimes missing
#' @importFrom stringi stri_split_boundaries
#' @export
#' @return This returns a string vector.
#' @examples mywords<-c("Hospital Number","Patient Name:","DOB:","General Practitioner:",
#' "Date received:","Clinical Details:","Macroscopic description:",
#' "Histology:","Diagnosis:")
#' CleanResults<-textPrep(PathDataFrameFinal$PathReportWhole,mywords,NegEx="TRUE",Extractor="1",ExtractPOS="2")

textPrep<-function(inputText,delim,NegEx=c('TRUE','FALSE'),Extractor=c('1','2'),ExtractPOS=c('1','2')){
  
  #1. Flatten the text
  inputText<-tolower(inputText)
  
  #1b General cleanup tasks
  inputText <- ColumnCleanUp(inputText)
  
  #2a . Fuzzy find and replace and term mapping using the find and replace function above using the Location list
  
  HistolType<-paste0(unlist(HistolType(),use.names=F),collapse="|")
  LocationList<-paste0(unlist(LocationList(),use.names=F),collapse="|")
  EventList<-paste0(unlist(EventList(),use.names=F),collapse="|")
  
  #Spellcheck using the lexicons as reference
  L <- tolower(str_split(LocationList,"\\|"))
  inputText<-Reduce(function(x, nm) spellCheck(nm, L[[nm]], x), init = inputText, names(L))
  L <- tolower(str_split(HistolType,"\\|"))
  inputText<-Reduce(function(x, nm) spellCheck(nm, L[[nm]], x), init = inputText, names(L))
  L <- tolower(unique(unlist(EventList, use.names = FALSE)))
  inputText<-Reduce(function(x, nm) spellCheck(nm, L[[nm]], x), init = inputText, names(L))
  
  
  #3.Remove all the negative phrases from the report if the parameter has been supplied
  
  #Need to write here if the NegativeRemove has been ticked then should use it
  
  if (missing(NegEx)||NegEx=="TRUE")
    {
  inputText<-NegativeRemove(inputText)
  }
  
  #4. Need to map the terms to the lexicons to make sure everything standardised.
  inputText<-DictionaryInPlaceReplace(inputText,LocationList())
  inputText<-DictionaryInPlaceReplace(inputText,EventList())
  inputText<-DictionaryInPlaceReplace(inputText,HistolType())
  

  #returns a lower case version
  inputText<-tolower(inputText)
  
  #Merge the POS frame with the original text so tagging happens right at the beginning
  #Will also need to add the Extractor output to the dataframe.
  
  standardisedTextOutput<-stri_split_boundaries(inputText, type="sentence")
  standardisedTextOutput<-lapply(standardisedTextOutput, function(x) paste0(unlist(x),collapse="\n"))
  

  
  
  #If the more complex Extractor is required:
  if (missing(Extractor)||Extractor=="1")
  {
    MyCompleteFrame<-Extractor(as.character(standardisedTextOutput),tolower(delim))
  }
  
  
  #If the normal Extractor is required:
  if (Extractor=="2")
  {
    
    #Convert the delimiters into a list and use it to initiate an empty data frame 
    #which also contains the original column:
    #EndoscTree<-list(delim)
    
    easydf <- data.frame(matrix(ncol = length(delim),nrow=length(inputText)))
    
    #Make sure the delimiters are lower case as the text will be by now
    delim<-tolower(delim)
    #Name the new dataframe columns
    #colnames(easydf)<-delim
    easydf$inputText<-inputText
    for(i in 1:(length(delim)-1)) {
      MyCompleteFrame<-Extractor2(easydf,'inputText',as.character(delim[i]),
                       as.character(delim[i+1]),as.character(delim[i]))
    }
    
  }
  

  #Optionally add the POS (parameter driven)
  
  if (ExtractPOS=="1")
  {
    #Create the dataframe with all the POS extracted:
    MyPOSframe<-EndoPOS(as.character(standardisedTextOutput))
    
    #Create a column in both dataframes that can act as a join
    MyPOSframe$RowIndex<-as.numeric(rownames(MyPOSframe))
    MyCompleteFrame$RowIndex<-as.numeric(rownames(MyCompleteFrame))
    
    #Now merge the POS tags and the extraction:
    MyCompleteFrame<-merge(MyCompleteFrame,MyPOSframe,by="RowIndex")
    MyCompleteFrame<-data.frame(MyCompleteFrame,stringsAsFactors = FALSE)
  }
  if (missing(ExtractPOS)||ExtractPOS=="2")
  {
    MyCompleteFrame<-MyCompleteFrame
  }
  
    #Last minute clean up:
    names(MyCompleteFrame) <- gsub(".", "", names(MyCompleteFrame), fixed = TRUE)
  
  return(MyCompleteFrame)
}

#' Parts of speech tagging for reports
#'
#' This uses udpipe to tag the text. It then compresses all of the text 
#' so you have continuous POS tagging or the whole text. The udpipe package has to be
#' pre downloaded to run this.
#' 
#'
#' @param inputString The input string vector
#' @keywords Macroscopic
#' @importFrom stringr str_replace
#' @importFrom udpipe udpipe_download_model udpipe_load_model udpipe_annotate cbind_morphological
#' @export
#' @examples library(udpipe)
#' 
#' #Just some quick cleaning up- this will be done in the actual data set eventually 
#' #Myendo$OGDReportWhole<-gsub("\\.\\s+\\,"," ",Myendo$OGDReportWhole)
#' #Myendo$OGDReportWhole<-gsub("^\\s+\\,"," ",Myendo$OGDReportWhole)
#' #Myendo$RowIndex<-as.numeric(rownames(Myendo))
#' 
#' #We will only use the first 100 
#' #Myendo2<-head(Myendo,100)
#' 
#' #Run the function
#' #MyPOSframe<-EndoPOS(Myendo2$OGDReportWhole) #returns a dataframe
#' 
#' #Then merge the MyPOSframe with the original by row number.
#' #Myendo$RowIndex<-as.numeric(rownames(Myendo))
#' #Get the whole merged dataset with all the POS tags and morphological
#' #and all the dependecies.
#' #MergedUp<-merge(Myendo2,MyPOSframe,by.x="RowIndex",by.y="doc_id")



EndoPOS<-function(inputString){
  #Get into a tokenised form first
  #Have to do this on the raw pre-prepared data so that sentences can be recognised.
  #Get the model from the data folder to save user from having to download it each time.
  udmodel_english<-udpipe_load_model(file = "~/EndoMineR/inst/POS_Corpus/english-ewt-ud-2.3-181115.udpipe")
  x <- udpipe_annotate(udmodel_english, x = inputString)
  x2 <- as.data.frame(x)

  
  
  
  
  #To get all in one long cell per original document:
  Newx<-x2 %>% group_by(doc_id,sentence_id)  %>% summarise(upos = paste(upos, collapse=";"),
                                                           sentence=paste(unique(sentence), collapse=";"),
                                                        xpos = paste(xpos, collapse=";"),
                                                        feats = paste(feats, collapse=";"),
                                                        head_token_id = paste(head_token_id, collapse=";"),
                                                        dep_rel = paste(dep_rel, collapse=";"),
                                                        deps = paste(deps, collapse=";"),
                                                        misc = paste(misc, collapse=";"))%>%group_by(doc_id)
  #has_morph = paste(has_morph, collapse=";"),
  #morph_abbr = paste(morph_abbr, collapse=";"),
  #morph_case = paste(morph_case, collapse=";"),
  #morph_definite = paste(morph_definite, collapse=";"),
  #morph_degree = paste(morph_degree, collapse=";"),
  #morph_gender = paste(morph_gender, collapse=";"),
  #morph_mood = paste(morph_mood, collapse=";"),
  #morph_number = paste(morph_number, collapse=";"),
  #morph_numtype = paste(morph_numtype, collapse=";"),
  #morph_person = paste(morph_person, collapse=";"),
  #morph_prontype = paste(morph_prontype, collapse=";"),
  #morph_tense = paste(morph_tense, collapse=";"),
  #morph_typo = paste(morph_typo, collapse=";"),
  #morph_verbform = paste(morph_verbform, collapse=";")
  #morph_voice = paste(morph_voice, collapse=";"))
  
  Newx<-data.frame(Newx)
  
  
  Newxdoc<-Newx %>% 
    group_by(doc_id) %>% summarise(
      sentence = paste(sentence, collapse="\n"),
      upos = paste(upos, collapse="\n"),
      xpos= paste(collapse="\n"),
      feats = paste(feats, collapse="\n"),
      head_token_id = paste(head_token_id, collapse="\n"),
      dep_rel = paste(dep_rel, collapse="\n"),
      deps = paste(deps, collapse="\n"),
      misc = paste(misc, collapse="\n"))
  #has_morph = paste(has_morph, collapse="\n"),
  #morph_abbr = paste(morph_abbr, collapse="\n"),
  #morph_case = paste(morph_case, collapse="\n"),
  #morph_definite = paste(morph_definite, collapse="\n"),
  #morph_degree = paste(morph_degree, collapse="\n"),
  #morph_gender = paste(morph_gender, collapse="\n"),
  #morph_mood = paste(morph_mood, collapse="\n"),
  #morph_number = paste(morph_number, collapse="\n"),
  #morph_numtype = paste(morph_numtype, collapse="\n"),
  #morph_person = paste(morph_person, collapse="\n"),
  #morph_poss = paste(morph_poss, collapse="\n"),
  #morph_prontype = paste(morph_prontype, collapse="\n"),
  #morph_tense = paste(morph_tense, collapse="\n"),
  #morph_typo = paste(morph_typo, collapse="\n"),
  #morph_verbform = paste(morph_verbform, collapse="\n"),
  #morph_voice = paste(morph_voice, collapse="\n"))
  
  # Need to convert the docids as they are alphabetically grouped, to allow merge 
  # with original dataframe
  
  Newxdoc$doc_id<-as.numeric(gsub("doc","",Newxdoc$doc_id))
  Newxdoc<-data.frame(Newxdoc[order(Newxdoc$doc_id),],stringsAsFactors=FALSE)
  #Newxdoc$sentence<-OriginalReport
  return(Newxdoc)
}


#' Extracts the columns from the raw report
#'
#' This is the main extractor for the Endoscopy and Histology report.
#' This depends on the user creating a list of words or characters that
#' act as the words that should be split against. The list is then fed to the
#' Extractor in a loop so that it acts as the beginning and the end of the
#' regex used to split the text. Whatever has been specified in the list
#' is used as a column header. Column headers don't tolerate special characters
#' like : or ? and / and don't allow numbers as the start character so these
#' have to be dealt with in the text before processing
#'
#' @param inputString the column to extract from
#' @param delim the vector of words that will be used as the boundaries to
#' extract against
#' @importFrom stringr str_extract
#' @importFrom tidyr separate
#' @importFrom rlang sym
#' @keywords Extraction
#' @export
#' @examples
#' # As column names cant start with a number, one of the dividing
#' # words has to be converted
#' # A list of dividing words (which will also act as column names)
#' # is then constructed
#' mywords<-c("Hospital Number","Patient Name:","DOB:","General Practitioner:",
#' "Date received:","Clinical Details:","Macroscopic description:",
#' "Histology:","Diagnosis:")
#' Mypath2<-Extractor(PathDataFrameFinal$PathReportWhole,mywords)
#'

Extractor <- function(inputString, delim) {
  
  #Save inputString so can be merge back in as the origincal for later
  inputStringForLater<- inputString
  
  #Create dataframe for tidyverse usage
  inputStringdf <- data.frame(inputString,stringsAsFactors = FALSE)
  
  #Do the separation according to delimiters
  inputStringdf <- inputStringdf %>%
    tidyr::separate(inputString, into = c("added_name",delim),
                    sep = paste(delim, collapse = "|"),
                    extra = "drop", fill = "right")
  
  #Make sure columns names are correct
  names(inputStringdf) <- gsub(".", "", names(inputStringdf), fixed = TRUE)
  
  #Get rid of the errant first column 
  inputStringdf <- inputStringdf [,-1]
  
  #Add the original column back in so have the original reference
  inputStringdf$Original<- inputString
  inputStringdf <-data.frame(inputStringdf,stringsAsFactors = FALSE)
  names(inputStringdf)<-gsub(".","",names(inputStringdf),fixed=TRUE)
  return(inputStringdf)
}





#' Extractor2
#'
#' This is the alternative extractor for the Endoscopy and Histology report.
#' THis performs the same essentially as the main extractor but is useful when the
#' semi-structured text is organised in a non-standard way ie the delimiting text is not always in the same order
#' As per the main Extractor, This function on the user creating a list of words or characters that
#' act as the words that should be split against. The list is then fed to the
#' Extractor in a loop so that it acts as the beginning and the end of the
#' regex used to split the text. Whatever has been specified in the list
#' is used as a column header. Column headers don't tolerate special characters
#' like : or ? and / and don't allow numbers as the start character so these
#' have to be dealt with in the text before processing
#'
#' @param x the dataframe
#' @param y the column to extract from
#' @param stra the start of the boundary to extract
#' @param strb the end of the boundary to extract
#' @param t the column name to create
#' @importFrom stringr str_extract
#' @keywords Extraction
#' @export
#' @examples v<-TheOGDReportFinal
#' Myendo<-TheOGDReportFinal
#' Myendo$OGDReportWhole<-gsub('2nd Endoscopist:','Second endoscopist:',
#' Myendo$OGDReportWhole)
#' 
#' EndoscTree<-list('Hospital Number:','Patient Name:','General Practitioner:',
#' 'Date of procedure:','Endoscopist:','Second Endoscopist:','Medications',
#' 'Instrument','Extent of Exam:','Indications:','Procedure Performed:',
#' 'Findings:','Endoscopic Diagnosis:')
#' 
#' for(i in 1:(length(EndoscTree)-1)) {
#'  Myendo<-Extractor2(Myendo,'OGDReportWhole',as.character(EndoscTree[i]),
#'  as.character(EndoscTree[i+1]),as.character(EndoscTree[i]))
#' }
#' res<-Myendo


Extractor2 <- function(x, y, stra, strb, t) {
  
  t <- gsub("[^[:alnum:],]", " ", t)
  
  t <- gsub(" ", "", t, fixed = TRUE)
  
  x[, t] <- stringr::str_extract(x[, y], stringr::regex(paste(stra,
                                                              "(.*)", strb, sep = ""), dotall = TRUE))
  x[, t] <- gsub("\\\\.*", "", x[, t])
  
  names(x[, t]) <- gsub(".", "", names(x[, t]), fixed = TRUE)
  x[, t] <- gsub("       ", "", x[, t])
  x[, t] <- gsub(stra, "", x[, t], fixed = TRUE)
  if (strb != "") {
    x[, t] <- gsub(strb, "", x[, t], fixed = TRUE)
  }
  x[, t] <- gsub("       ", "", x[, t])
  x[, t]<- ColumnCleanUp(x[, t])
  
  
  return(x)
}



#' Dictionary In Place Replace
#'
#' This maps terms in the text replaces them with the 
#' standardised term (mapped in the lexicon file) within the text.
#' It is used within the textPrep function.

#'
#' @param inputString the input string
#' @param list The replacing list
#' @keywords Replace
#' @export
#' @return This returns a character vector
#' @examples inputText<-DictionaryInPlaceReplace(TheOGDReportFinal$OGDReportWhole,LocationList())



DictionaryInPlaceReplace <- function(inputString,list) {

  key<-names(list)
  value<-as.character(t(data.frame(list,stringsAsFactors=FALSE))[,1])
  list<-data.frame(key,value,stringsAsFactors = FALSE)
  
  new_string <- inputString
  vapply(1:nrow(list),
         function (k) {
           new_string <<- gsub(list$key[k], list$value[k], new_string)
           0L
         }, integer(1))
  
  return(new_string)
}











#' Removes negative and normal sentences
#'
#' Extraction of the Negative sentences so that normal findings can be
#' removed and not counted when searching for true diseases. eg remove
#' No evidence of candidal infection so it doesn't get included if
#' looking for candidal infections.
#' It should be used after the Extractor and the optional
#' NewLines has been used. It can be used as part of the other functions
#' or as a way of providing a 'positive diagnosis only' type output (see
#' HistolDx)
#' @param inputText column of interest
#' @keywords Negative Sentences
#' @importFrom stringr str_replace
#' @export
#' @return This returns a column within a dataframe. THis should be changed to a 
#' character vector eventually
#' @examples # Build a character vector and then
#' # incorporate into a dataframe
#' anexample<-c("There is no evidence of polyp here",
#' "Although the prep was poor,there was no adenoma found",
#' "The colon was basically inflammed, but no polyp was seen",
#' "The Barrett's segment was not biopsied",
#' "The C0M7 stretch of Barrett's was flat")
#' anexample<-data.frame(anexample)
#' names(anexample)<-"Thecol"
#' # Run the function on the dataframe and it should get rid of sentences (and
#' # parts of sentences) with negative parts in them.
#' hh<-NegativeRemove(anexample$Thecol)

NegativeRemove <- function(inputText) {
  # Conjunctions
  inputText <- gsub(
    "(but|although|however|though|apart| -|otherwise
    |unremarkable|\\,)[a-zA-Z0-9_ ]+(no |negative|
    unremarkable|-ve|normal).*?(\\.|\\n|:|$)\\R*",
    "\\.\n",
    inputText,
    perl = TRUE,
    ignore.case = TRUE
    )
  inputText <-
    gsub(
      "(no |negative|unremarkable|-ve| normal) .*?([Bb]ut|
      [Aa]lthough| [Hh]owever| [Tt]hough| [Aa]part| -|[Oo]therwise|
      [Uu]nremarkable)\\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
      )
  # Nots
  inputText<-
    gsub(
      ".*(?:does|is|was|were|are|have) not.*?(\\.|\n|:|$)\\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
    )
  inputText <-
    gsub(
      "not (biop|seen).*?(\\.|\n|:|$)\\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
    )
  # Nos
  inputText <-
    gsub(
      ".*(?:((?<!with)|(?<!there is )|(?<!there are ))\\bno\\b(?![?:A-Za-z])|
      ([?:]\\s*N?![A-Za-z])).*\\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
      )
  
  #Withouts
  inputText <-
    gsub(
      ".*without.*\\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
    )
  
  
  inputText <-
    gsub(
      ".*(:|[?])\\s*(\\bno\\b|n)\\s*[^A-Za-z0-9].*?(\\.|\n|:|$)
      \\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
    )
  inputText <-
    gsub(
      ".*(negative|neither).*?(\\.|\n|:|$)\\R*",
      "",
      inputText,
      perl = TRUE,
      ignore.case = TRUE
    )
  # Keep abnormal in- don't ignore case as it messes it up
  inputText <- str_replace(inputText,
                                     ".*(?<!b)[Nn]ormal.*?(\\.|\n|:|$)", "")
  # Other negatives
  inputText <- gsub(
    ".*there (is|are|were) \\bno\\b .*?(\\.|\n|:|$)\\R*",
    "",
    inputText,
    perl = TRUE,
    ignore.case = TRUE
  )
  inputText <- gsub(
    "(within|with) (normal|\\bno\\b) .*?(\\.|\n|:|$)\\R*",
    "",
    inputText,
    perl = TRUE,
    ignore.case = TRUE
  )
  # Specific cases
  inputText <- gsub(
    ".*duct.*clear.*?(\\.|\n|:|$)\\R*",
    "",
    inputText,
    perl = TRUE,
    ignore.case = TRUE
  )
  # Unanswered prompt lines
  inputText <- gsub(".*:(\\.|\n)\\R*",
                              "",
                    inputText,
                              perl = TRUE,
                              ignore.case = TRUE)
  
  
  # Time related phrases eg post and previous
  inputText <- gsub(" (post|previous|prior)[^a-z].+?[A-Za-z]{3}",
                              " TIME_REPLACED",
                    inputText,
                              perl = TRUE,
                              ignore.case = TRUE)
  
  
  return(inputText)
}

#' Find and Replace function
#'
#' This is a helper function for finding and replacing from dictionaries like the event list
#' It uses fuzzy find and replace to account for spelling errors
#' @keywords Find and replace
#' @importFrom utils aregexec
#' @param pattern the pattern to look for
#' @param replacement the pattern replaceme with
#' @param x the target string
#' @return This returns a character vector
#' @examples L <- tolower(stringr::str_split(HistolType(),"\\|"))
#' inputText<-TheOGDReportFinal$OGDReportWhole
#' inputText<-Reduce(function(x, nm) spellCheck(nm, L[[nm]], x), init = inputText, names(L))
#' 


spellCheck <- function(pattern, replacement, x, fixed = FALSE, ...) {
  m <- aregexec(pattern, x, fixed = fixed,ignore.case = T)
  r <- regmatches(x, m)
  lens <- lengths(r)
  if (all(lens == 0)) return(x) else
    replace(x, lens > 0, mapply(sub, r[lens > 0], replacement, x[lens > 0]))
}

#' Tidies up messy columns
#'
#' This does a general clean up of whitespace,
#' semi-colons,full stops at the start
#' of lines and converts end sentence full stops to new lines.
#' @param vector column of interest
#' @keywords Cleaner
#' @export
#' @importFrom stringr str_replace 
#' @importFrom stringi stri_split_boundaries
#' @return This returns a character vector
#' @examples ii<-ColumnCleanUp(Myendo$Findings)


ColumnCleanUp <- function(vector) {
  
  
  #Optimise for tokenisation eg full stops followed by a number need to change so add a Letter before the number
  vector<-gsub("\\.\\s*(\\d)","\\.T\\1",vector)
  vector<-gsub("([A-Za-z]\\s*)\\.(\\s*[A-Za-z])","\\1\n\\2",vector)
  vector<-gsub("([A-Za-z]+.*)\\?(.*[A-Za-z]+.*)","\\1 \\2",vector)
  vector<-gsub("\\.,","\\.",vector)
  vector<-gsub(",([A-Z])","\\.\\1",vector)
  vector<-gsub("\\. ,",".",vector)
  vector<-gsub("\\.\\s+\\,"," ",vector)
  vector<-gsub("^\\s+\\,"," ",vector)
  vector<-gsub("\\\\.*", "", vector)
  vector<-gsub("       ", "", vector)
  
  #Get rid of query type punctuation:
  vector<-gsub("(.*)\\?(.*[A-Za-z]+)","\\1 \\2",vector)
  vector<-gsub("'","",vector,fixed=TRUE)
  
  #Have to tokenize here so you can strip punctuation without getting rid of newlines
  standardisedTextOutput<-stri_split_boundaries(vector, type="sentence")
  
  #Get rid of whitespace
  standardisedTextOutput<-lapply(standardisedTextOutput, function(x) trimws(x))
  
  #Get rid of trailing punctuation
  standardisedTextOutput<-lapply(standardisedTextOutput,function(x) gsub("^[[:punct:]]+","",x))
  standardisedTextOutput<-lapply(standardisedTextOutput,function(x) gsub("[[:punct:]]+$","",x))
  #Question marks result in tokenized sentences so whenever anyone write query Barrett's, it gets split.
  standardisedTextOutput<-lapply(standardisedTextOutput,function(x) gsub("([A-Za-z]+.*)\\?(.*[A-Za-z]+.*)","\\1 \\2",x))
  standardisedTextOutput<-lapply(standardisedTextOutput,function(x) gsub("(Dr.*?[A-Za-z]+)|([Rr]eported.*)|([Dd]ictated by.*)","",x))
  
  
  #Get rid of strange things
  standardisedTextOutput<-lapply(standardisedTextOutput,function(x) gsub("\\.\\s+\\,"," ",x))
  standardisedTextOutput<-lapply(standardisedTextOutput,function(x) gsub("^\\s+\\,"," ",x))
  retVector<-sapply(standardisedTextOutput, function(x) paste(x,collapse="\n"))
  return(retVector)
}











############## Extraction Utilities - Basic ###################


#' Extract sentences with the POS tags desired
#'
#' This uses udpipe to tag the text. It then compresses all of the text 
#' so you have continuous POS tagging or the whole text. The udpipe package has to be
#' pre downloaded to run this.
#' 
#'
#' @param POS_seq The POS tag sequence to extract
#' @param columnPOS The column with the POS tags
#' @param columnSentence The column with the sentence
#' @keywords Macroscopic
#' @export
#' @examples #Has to be after POS extraction is done
#' #mylist<-POS_Extract("NOUN;ADJ;NOUN",MergedUp$upos,MergedUp$sentence)
#' #MergedUp$Extr<-mylist


POS_Extract<-function(POS_seq,columnPOS,columnSentence){
  #Convert the POS tags to list nested list
  columnPOS<-strsplit(columnPOS,"\n")
  
  #Search the list for the tags that match, and keep the matching indices in a list
  myIndexes<-lapply(columnPOS,function(x) grep(POS_seq,x))
  
  #Get the index for the matched tags
  
  #Return the index of the matched tags for the other columns too
  # Select the corresponding indices for the next column:
  columnSentence<-strsplit(columnSentence,"\n")
  
  #Select the indices
  my<-Map(`[`, columnSentence, myIndexes)
  
  
  #For each part of the list select out the index of the list:
  return(my)
}

#' Extrapolate from Dictionary
#'
#' Provides term mapping and extraction in one.
#' Standardises any term according to a mapping lexicon provided and then
#' extracts the term. Thus is
#' different to the DictionaryInPlaceReplace in that it provides a new column
#' with the extracted terms as opposed to changing it in place
#'
#' @param inputString The text string to process
#' @param list of words to iterate through
#' @keywords Withdrawal
#' @importFrom fuzzyjoin regex_left_join
#' @importFrom dplyr as_tibble pull
#' @export
#' @examples #Firstly we extract histology from the raw report
#' # The function then standardises the histology terms through a series of
#' # regular expressions and then extracts the type of tissue 
#' Mypath$Tissue<-ExtrapolatefromDictionary(Mypath$Histology,HistolType())
#' rm(MypathExtraction)




ExtrapolatefromDictionary<-function(inputString,list){
  #lower case the input string
  inputString<-tolower(inputString)
  
  #Get the names from the named list
  mylist<-paste0(unlist(list,use.names=F),collapse="|")
  
  #Make the inputstrings unique
  ToIndex<-lapply(inputString, function(x) unique(x))
  #Give each an index in the list (taken from the location list)
  
  #The results to replace in the string
  replace<-names(list)
  
  #The result of the replacement 
  replaceValue<-paste0(unlist(list,use.names=F))
  
  #Create a dataframe
  df1<-data.frame(key = replace, val = replaceValue)
  
  #Create a tibble to merge with the list
  d1 <- as_tibble(df1)
  
  
  #Select the elements that have characters in them
  i1 <- lengths(ToIndex) > 0 
  
  #Do the merge. This takes the key to lookup and then if found, replaces
  #the value with value associated with it in the table. I think the pull
  #function also creates a new column with the value in it. This is an important
  #function as uses a table lookup
  ToIndex[i1] <- map(ToIndex[i1], ~ 
                       tibble::tibble(key = .x) %>%
                       fuzzyjoin::regex_left_join(d1) %>%
                       pull(val))
  
  #This unlists the nested list
  ToIndex<-lapply(ToIndex, function(x) unlist(x,recursive=F))
  
  #This collapses the list so that the output is a single string
  ToIndex<-unlist(lapply(ToIndex, function(x) paste(x,collapse=";")))
  
  return(ToIndex)
}

############## Extraction Utilities- Colocation ###################

#' EntityPairs_OneSentence 
#'
#' Use to see if words from two lists co-exist within a sentence. Eg site and tissue type.
#' This function only looks in one sentence for the two terms. This should be ised a
#' @keywords PathPairLookup
#' @param inputText The relevant pathology text column
#' @param list1 First list to refer to
#' @param list2 The second list to look for
#' @importFrom purrr flatten_chr map_chr map map_if
#' @export
#' @examples # tbb<-EntityPairs_OneSentence(Mypath$Histology,HistolType(),LocationList())

EntityPairs_OneSentence<-function(inputText,list1,list2){
  
  #dataframe<-data.frame(dataframe,stringsAsFactors = FALSE)
  list1<-paste0(unlist(list1,use.names=F),collapse="|")
  list2<-paste0(unlist(list2,use.names=F),collapse="|")
  
  #text<-textPrep(inputText)
  text<-standardisedTextOutput<-stri_split_boundaries(inputText, type="sentence")
  r1 <-lapply(text,function(x) Map(paste, str_extract_all(tolower(x),tolower(list2)), str_extract_all(tolower(x),tolower(list1)), MoreArgs = list(sep=":")))
  
  r1<-lapply(r1,function(x) unlist(x))
  #Unlist into a single row-This should output a character vector
  out<-lapply(r1,function(x) paste(x,collapse=","))
  
  return(out)
}

#' EntityPairs_TwoSentence
#'
#' This is used to look for relationships between site and event especially for endoscopy events
#' @keywords Find and replace
#' @param inputString The relevant pathology text column
#' @param list1 The intial list to assess
#' @param list2 The other list to look for
#' @importFrom stringr str_replace_na str_c str_split str_which str_extract_all regex str_subset
#' @importFrom stringi stri_split_boundaries
#' @importFrom rlang is_empty
#' @importFrom purrr flatten_chr map_chr map map_if
#' @export
#' @examples # tbb<-EntityPairs_TwoSentence(Myendo$Findings,EventList(),HistolType())

EntityPairs_TwoSentence<-function(inputString,list1,list2){
    
  #Prepare the text to be back into a tokenised version.
  #text<-textPrep(inputText)
  text<-standardisedTextOutput<-stri_split_boundaries(inputString, type="sentence")
  text<-lapply(text,function(x) tolower(x))
  
  
  #Some clean up to get rid of white space- all of this prob already covered in the ColumnCleanUp function but for investigation later
  text<-lapply(text,function(x) gsub("[[:punct:]]+"," ",x))
  #Prepare the list to use as a lookup:
  tofind <-paste(tolower(list2),collapse="|")
  
  #Prepare the second list to use as a lookup
  EventList<-unique(tolower(unlist(list1,use.names = FALSE)))
  
  
  text<-sapply(text,function(x) {
    
    #Cleaning
    x<-trimws(x)

    
    
    #Prepare the text so that all empty text is replaced with NA and 
    #ready for processing
    try(words <-
          x %>%
          unlist() %>%
          str_replace_na()%>%
          str_c(collapse = ' ') %>%
          str_split(' ') %>%
          `[[`(1))
    
    
    words<-words[words != ""] 
    x1 <- str_extract_all(tolower(x),tolower(paste(unlist(list1), collapse="|")))
    i1 <- which(lengths(x1) > 0)
    
    
    try(if(any(i1)) {
      EventList %>%
        map(
          ~words %>%
            str_which(paste0('^.*', .x)) %>%
            map_chr(
              ~words[1:.x] %>%
                str_c(collapse = ' ') %>%
                
                str_extract_all(regex(tofind, ignore_case = TRUE)) %>%
                map_if(rlang::is_empty, ~ NA_character_) %>%
                flatten_chr()%>%
                `[[`(length(.)) %>%
                
                .[length(.)]
            ) %>%
            paste0(':', .x)
        ) %>%
        unlist() %>%
        str_subset('.+:')
      
    } else "")
    
  }
  )
  return(text)
}





