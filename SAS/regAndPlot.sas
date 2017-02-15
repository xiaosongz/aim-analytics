/* Create a macro to do EDA, regression, and residual plotting */
%macro regAndPlot(data, y, x);
    /* Double quotes are needed to allow substitution */
    TITLE "EDA of &data: &y on &x";
    /* RL is regression, linear for adding a fit line to a plot */
    SYMBOL INTERPOL=RL VALUE=plus;
    PROC GPLOT DATA=&data;
      PLOT &y * &x;
    RUN;

    TITLE "Regression analysis for &data";
    PROC GLM DATA=&data;
      MODEL &y = &x / SOLUTION;
      OUTPUT OUT=_temp RESIDUAL=res PREDICTED=pred;
    RUN;

    TITLE;
    PROC UNIVARIATE DATA=_temp NOPRINT;
      VAR res;
      OUTPUT OUT=_tmpstd STD=stdev;
    RUN;

    DATA _NULL_;
      SET _tmpstd;
      CALL SYMPUT('resSD',stdev);
    RUN;

    TITLE "Regression with &data data: &y on &x";
    TITLE2 'Quantile normal plot of residuals';
    PROC UNIVARIATE DATA=_temp NOPRINT;
      VAR res;
      QQPLOT / NORMAL (MU=0 SIGMA=&resSD COLOR=red);
    RUN;

    TITLE2 'Residual vs. fit plot';
    PROC GPLOT DATA=_temp;
      PLOT res*pred / VREF=0;
    RUN;  
%mend regAndPlot;
