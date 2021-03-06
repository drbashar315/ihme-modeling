
# runtime configuration

if (Sys.info()["sysname"] == "Linux") {

  j <- "ADDRESS"
  h <- "/ADDRESS/USERNAME/"

} else {

  j <- "ADDRESS"
  h <- "ADDRESS"

}

require(data.table)
require(feather)


loc_id<-c(33 ,    34 ,    35 ,    36 ,    37 ,    38 ,    39 ,    40 ,    41 ,    43 ,    44 ,    45 ,    46 ,
          47 ,    48 ,    50 ,    49 ,    53660 , 53661 , 53662 , 53663 , 53664 , 53665 , 53666 , 53667 , 53668 ,
          53669 , 53670 , 53671 , 53672 , 53673 , 53674 , 53675 , 52 ,    53 ,    54 ,    55 ,    57 ,    58 ,
          59 ,    60 ,    61 ,    44971 , 44983 , 44924 , 44936 , 44903 , 44904 , 44945 , 44966 , 44987 , 44952 ,
          44974 , 44907 , 44986 , 44942 , 44926 , 44908 , 44980 , 44943 , 44975 , 44982 , 44963 , 44954 , 44922 ,
          44909 , 44935 , 44973 , 44961 , 44910 , 44927 , 44911 , 44984 , 44920 , 44912 , 44928 , 44923 , 44955 ,
          44929 , 44976 , 44977 , 44956 , 44913 , 44957 , 44953 , 44981 , 44930 , 44932 , 44967 , 44947 , 44968 ,
          44940 , 44941 , 44933 , 44921 , 44970 , 44948 , 44949 , 44944 , 44979 , 44950 , 44969 , 44938 , 44914 ,
          44985 , 44958 , 44931 , 44959 , 44915 , 44946 , 44962 , 44916 , 44978 , 44918 , 44917 , 44965 , 44951 ,
          44960 , 44905 , 44937 , 44925 , 44906 , 44964 , 44919 , 44972 , 44934 , 44939 , 50559 , 71 ,    44850 ,
          44851 , 66 ,    35446 , 35428 , 35425 , 35435 , 35461 , 35441 , 35463 , 35430 , 35444 , 35433 , 35457 ,
          35424 , 35451 , 35431 , 35440 , 35426 , 35460 , 35469 , 35437 , 35462 , 35466 , 35449 , 35447 , 35427 ,
          35468 , 35443 , 35465 , 35452 , 35438 , 35467 , 35456 , 35470 , 35450 , 35464 , 35434 , 35448 , 35455 ,
          35445 , 35432 , 35459 , 35436 , 35454 , 35439 , 35453 , 35429 , 35458 , 35442 , 68 ,    69 ,    101 ,
          349 ,   523 ,   524 ,   525 ,   526 ,   527 ,   528 ,   529 ,   530 ,   531 ,   532 ,   533 ,   534 ,
          535 ,   536 ,   537 ,   538 ,   539 ,   540 ,   541 ,   542 ,   543 ,   544 ,   545 ,   546 ,   547 ,
          548 ,   549 ,   550 ,   551 ,   552 ,   553 ,   554 ,   555 ,   556 ,   557 ,   558 ,   559 ,   560 ,
          561 ,   562 ,   563 ,   564 ,   565 ,   566 ,   567 ,   568 ,   569 ,   570 ,   571 ,   572 ,   573 ,
          97 ,    98 ,    99 ,    74 ,    75 ,    76 ,    77 ,    78 ,    79 ,    80 ,    81 ,    82 ,    83 ,
          84 ,    85 ,    35507 , 35511 , 35512 , 35509 , 35502 , 35501 , 35506 , 35496 , 35497 , 35505 , 35508 ,
          35494 , 35498 , 35499 , 35510 , 35514 , 35513 , 35503 , 35504 , 35495 , 35500 , 87 ,    88 ,    89 ,
          4914 ,  4911 ,  4918 ,  4915 ,  4928 ,  4912 ,  4921 ,  4923 ,  4926 ,  4913 ,  4910 ,  4920 ,  4922 ,
          4917 ,  53432 , 4927 ,  4919 ,  4916 ,  91 ,    367 ,   396 ,   92 ,    4944 ,  4940 ,  94 ,    44697 ,
          44698 , 44701 , 44694 , 44695 , 44693 , 44700 , 44699 , 44696 , 44716 , 44721 , 44717 , 44720 , 44719 ,
          44726 , 44723 , 44725 , 44724 , 44718 , 44722 , 44754 , 44729 , 44732 , 44735 , 44731 , 44748 , 44742 ,
          44744 , 44741 , 44745 , 44756 , 44743 , 44755 , 44740 , 44737 , 44736 , 44751 , 44757 , 44728 , 44738 ,
          44749 , 44750 , 44734 , 44753 , 44733 , 44727 , 44752 , 44739 , 44758 , 44747 , 44746 , 44730 , 44649 ,
          44643 , 44650 , 44654 , 44651 , 44646 , 44647 , 44644 , 44648 , 44652 , 44645 , 44653 , 44674 , 44676 ,
          44662 , 44664 , 44655 , 44658 , 44661 , 44670 , 44675 , 44660 , 44671 , 44677 , 44667 , 44668 , 44673 ,
          44659 , 44665 , 44656 , 44672 , 44657 , 44666 , 44669 , 44663 , 44765 , 44770 , 44760 , 44772 , 44764 ,
          44774 , 44769 , 44771 , 44775 , 44767 , 44773 , 44768 , 44777 , 44776 , 44761 , 44763 , 44766 , 44762 ,
          44759 , 44784 , 44790 , 44789 , 44791 , 44782 , 44779 , 44785 , 44781 , 44792 , 44783 , 44786 , 44778 ,
          44787 , 44788 , 44780 , 44714 , 44709 , 44708 , 44703 , 44715 , 44705 , 44704 , 44707 , 44711 , 44710 ,
          44712 , 44702 , 44713 , 44706 , 44692 , 44684 , 44682 , 44690 , 44679 , 44691 , 44685 , 44686 , 44681 ,
          44683 , 44678 , 44689 , 44687 , 44688 , 44680 , 433 ,   434 ,   4636 ,  122 ,   123 ,   121 ,   105 ,
          107 ,   108 ,   305 ,   106 ,   109 ,   110 ,   111 ,   112 ,   113 ,   114 ,   115 ,   385 ,   393 ,
          116 ,   117 ,   118 ,   119 ,   422 ,   133 ,   125 ,   126 ,   127 ,   128 ,   129 ,   4643 ,  4644 ,
          4645 ,  4646 ,  4649 ,  4650 ,  4647 ,  4648 ,  4652 ,  4653 ,  4654 ,  4655 ,  4656 ,  4657 ,  4651 ,
          4658 ,  4659 ,  4660 ,  4661 ,  4662 ,  4663 ,  4664 ,  4665 ,  4666 ,  4667 ,  4668 ,  4669 ,  4670 ,
          4671 ,  4672 ,  4673 ,  4674 ,  131 ,   132 ,   4750 ,  4751 ,  4753 ,  4752 ,  4754 ,  4755 ,  4756 ,
          4757 ,  4758 ,  4759 ,  4762 ,  4761 ,  4760 ,  4763 ,  4764 ,  4765 ,  4766 ,  4767 ,  4768 ,  4769 ,
          4772 ,  4770 ,  4771 ,  4773 ,  4775 ,  4774 ,  4776 ,  136 ,   160 ,   139 ,   140 ,   141 ,   143 ,
          44864 , 44865 , 44868 , 44869 , 44866 , 44870 , 44871 , 44872 , 44873 , 44874 , 44875 , 44876 , 44877 ,
          44878 , 44880 , 44882 , 44883 , 44884 , 44885 , 44886 , 44887 , 44879 , 44888 , 44889 , 44890 , 44891 ,
          44881 , 44892 , 44867 , 44893 , 44894 , 144 ,   145 ,   146 ,   147 ,   148 ,   149 ,   150 ,   151 ,
          152 ,   522 ,   153 ,   154 ,   155 ,   156 ,   157 ,   161 ,   162 ,   43908 , 43872 , 43909 , 43873 ,
          43910 , 43874 , 43911 , 43875 , 43913 , 43877 , 43916 , 43880 , 43917 , 43881 , 43918 , 43882 , 43919 ,
          43883 , 43920 , 43884 , 43921 , 43885 , 43922 , 43886 , 43923 , 43887 , 43924 , 43888 , 43926 , 43890 ,
          43927 , 43891 , 43928 , 43892 , 43929 , 43893 , 43930 , 43894 , 43931 , 43895 , 43932 , 43896 , 43934 ,
          43898 , 43935 , 43899 , 43936 , 43900 , 43937 , 43901 , 43938 , 43902 , 43939 , 43903 , 44539 , 44540 ,
          43940 , 43904 , 43941 , 43905 , 43942 , 43906 , 164 ,   53615 , 53616 , 53617 , 53618 , 53619 , 53620 ,
          53621 , 491 ,   492 ,   493 ,   494 ,   495 ,   496 ,   497 ,   498 ,   499 ,   500 ,   501 ,   502 ,
          354 ,   503 ,   504 ,   505 ,   506 ,   507 ,   508 ,   509 ,   361 ,   510 ,   511 ,   512 ,   513 ,
          514 ,   515 ,   516 ,   517 ,   518 ,   519 ,   520 ,   521 ,   7 ,     8 ,     298 ,   320 ,   25 ,
          22 ,    351 ,   23 ,    24 ,    376 ,   26 ,    369 ,   374 ,   380 ,   27 ,    28 ,    413 ,   29 ,
          416 ,   30 ,    10 ,    4709 ,  4726 ,  4717 ,  4725 ,  4715 ,  4737 ,  4720 ,  4713 ,  4721 ,  4722 ,
          4724 ,  4729 ,  4731 ,  4730 ,  4732 ,  4719 ,  4718 ,  4716 ,  4739 ,  4740 ,  4727 ,  4728 ,  4742 ,
          4741 ,  4712 ,  4738 ,  4735 ,  4734 ,  4736 ,  4733 ,  4711 ,  4714 ,  4710 ,  4723 ,  12 ,    13 ,
          14 ,    183 ,   15 ,    53536 , 53604 , 53605 , 53572 , 53568 , 53573 , 53537 , 53554 , 53610 , 53548 ,
          53547 , 53558 , 53535 , 53586 , 53579 , 53591 , 53552 , 53544 , 53566 , 53570 , 53594 , 53571 , 53565 ,
          53556 , 53578 , 53596 , 53602 , 53599 , 53597 , 53598 , 53595 , 53608 , 53582 , 53576 , 53534 , 53540 ,
          53541 , 53575 , 53545 , 53538 , 53539 , 53557 , 53592 , 53613 , 53585 , 53612 , 53564 , 53569 , 53590 ,
          53593 , 53533 , 53614 , 53574 , 53577 , 53583 , 53553 , 53543 , 53560 , 53561 , 53563 , 53551 , 53542 ,
          53559 , 53546 , 53555 , 53562 , 53584 , 53603 , 53580 , 53567 , 53600 , 53581 , 53601 , 53611 , 53607 ,
          53606 , 53550 , 53609 , 53549 , 53588 , 53589 , 53587 , 17 ,    186 ,   20 ,    18 ,    19 ,    168 ,
          169 ,   170 ,   171 ,   172 ,   173 ,   175 ,   176 ,   177 ,   178 ,   44861 , 44853 , 44854 , 44857 ,
          44862 , 44860 , 44859 , 44855 , 44856 , 44858 , 44852 , 35617 , 35618 , 35619 , 35620 , 35621 , 35622 ,
          35623 , 35624 , 35625 , 35626 , 35627 , 35628 , 35629 , 35630 , 35631 , 35632 , 35633 , 35634 , 35635 ,
          35636 , 35637 , 35638 , 35639 , 35640 , 35641 , 35642 , 35643 , 35644 , 35645 , 35646 , 35647 , 35648 ,
          35649 , 35650 , 35651 , 35652 , 35653 , 35654 , 35655 , 35656 , 35657 , 35658 , 35659 , 35660 , 35661 ,
          35662 , 35663 , 181 ,   182 ,   184 ,   185 ,   187 ,   435 ,   189 ,   190 ,   191 ,   193 ,   194 ,
          195 ,   482 ,   483 ,   484 ,   485 ,   486 ,   487 ,   488 ,   489 ,   490 ,   197 ,   198 ,   200 ,
          201 ,   202 ,   204 ,   207 ,   208 ,   209 ,   210 ,   211 ,   212 ,   213 ,   25318 , 25319 , 25320 ,
          25321 , 25322 , 25323 , 25324 , 25325 , 25326 , 25327 , 25328 , 25329 , 25330 , 25331 , 25332 , 25333 ,
          25334 , 25335 , 25336 , 25337 , 25338 , 25339 , 25340 , 25341 , 25342 , 25343 , 25344 , 25345 , 25346 ,
          25347 , 25348 , 25349 , 25350 , 25351 , 25352 , 25353 , 25354 , 203 ,   205 ,   206 ,   215 ,   216 ,
          217 ,   218)

YEARS<-rep(c(seq(1990,2019)),each=990)
length(YEARS)

LOCATION_ID<-rep(loc_id,30)
length(LOCATION_ID)

script <- file.path("/FILEPATH/PAF_calculation.R")
sge.output.dir<-"-j y -o /FILEPATH/USERNAME/output"
rshell<-file.path("FILEPATH/health_fin_forecasting_shell_singularity.sh")

#mem <- "-l m_mem_free=250G"
fthread <- "-l fthread=2"
runtime <- "-l h_rt=48:00:00"
archive <- "-l archive=TRUE" # or "" if no jdrive access needed
project<-"-P proj_custom_models"
project<-"-P proj_paf_temp"


lsize<-fread(paste0(j,"FILEPATH/locsize.csv"))
lsize[,mem:=ifelse(objsize>10000000000,300,150)]
MEM<-rep(lsize$mem,30)

############ Canada
MEM <- rep("250",30)


  for (i in 1:length(YEARS)){
    year<-YEARS[i]
    loc<-as.numeric((LOCATION_ID[i]))
    args <- paste(year,loc)
    jname <- paste0("-N paf",year,loc)
    mem<-paste0("-l m_mem_free=",MEM[i],"G")

    #NOTE: project, sge.output.dir, & rshell MUST be defined elsewhere in script
    system(paste("qsub",jname,mem,fthread,runtime,archive,project,"-q all.q",sge.output.dir,rshell,script,args))
    print(i)
  }



