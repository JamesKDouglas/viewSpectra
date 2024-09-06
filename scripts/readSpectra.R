# This library is necessary to import the OPUS file format, which actually has 3 spectra in it and a bunch of metadata.
#
library("opusreader2")


# I may use this library for manipulating spectra https://rdrr.io/github/henningte/ir/f/README.md

file_1 <- "/Users/jamesdouglas/ankors/AfterFestival2024/RViewSpectra/FirstTry/data/1-900-2024-07-25-JARA-005.0"
spectrum_1 <- read_opus(dsn = file_1)

# class(spectrum_1)
# names(spectrum_1)

meas_1 <- spectrum_1[["1-900-2024-07-25-JARA-005.0"]]

#handy functions for looking at objects are names(), str() (structure, not string), class()

# SC STANDS FOR SINGLE CHANNEL ab stands for absorbance. I'm not sure exactly what 
# they mean by single channel but perhaps it's some sort of simpler scan through 
# the wavelengths rather than the fourier transform method with the michelson interferometer
# I'm not sure why you would want to do that - why not just take background the same way you collect the best sample data?
# Maybe it helps with wavelength referencing or something.

plot(meas_1$sc_ref$wavenumbers, meas_1$sc_ref$data, type = "l", xlim = rev(range(meas_1$sc_ref$wavenumbers)))
plot(meas_1$sc_sample$wavenumbers,meas_1$sc_sample$data,  type = "l", xlim = rev(range(meas_1$sc_sample$wavenumbers)))

xSample<-meas_1$ab_no_atm_comp$wavenumbers
plot( meas_1$ab_no_atm_comp$wavenumbers,meas_1$ab_no_atm_comp$data, type = "l", xlim = rev(range(xSample)))

# Is ab_no_atm is a combination of sc_sample and sc_ref?
# I'd like to check by subtracting one from the other. 
# But the wavenumbers are slightly different, which makes it harder than simply subtracting one array from another.
str(meas_1$sc_ref$wavenumbers)
str(meas_1$sc_sample$wavenumbers)

#all I need to do is trim the start and end.

# xbt- "x background trimmed"
xbt <- meas_1$sc_ref$wavenumbers[5:1665]
str(xbt)
ybt <- meas_1$sc_ref$data[5:1665]

# now try subtracting
# Is there confusion here with regards to which gets subtracted from which? 
# It does look like the sample spectra is in transmission mode - notches downwards compared to the reference
subtracted <- ybt - meas_1$sc_sample$data

# plot(meas_1$sc_sample$wavenumbers, subtracted, type = "l", xlim = rev(range(meas_1$sc_sample$wavenumbers)))

#Can we get them both on a plot?
#Make an empty plot
plot(meas_1$sc_sample$wavenumbers, subtracted, type = "n", xlim = rev(range(meas_1$sc_sample$wavenumbers)), ylim = range(subtracted), 
     xlab = "X", ylab = "Y", main = "Multiple Lines Plot")

# red for sample-ref, 
lines(meas_1$sc_sample$wavenumbers, subtracted, type = "l", col = "red")
lines(meas_1$sc_sample$wavenumbers, meas_1$ab_no_atm_comp$data/7, type = "l", col = "blue")
lines(meas_1$sc_sample$wavenumbers, subtracted-meas_1$ab_no_atm_comp$data/7, type = "l", col = "black")

#They do look quite similar but the blue one has had something subtracted from it which could just be a baseline correction.
#Perhaps a rubberband?
#One way to test that is to perform a rubberband baseline correction and see if that makes a similar chart
# so perform a rubberband correction on the red line.
# for that I will try to use hyperSpec

# I can't get hyperSpec working. I have some simple data in two clean lists - wavelength and absorbance
# But after a few days of trying I'm unable to get hyperSpec to make an object out of them.

# The documentation is short and confused. The best plot I can get is not a real plot but just a diagonal line.

require(hyperSpec)
wavenumbers <- meas_1$sc_sample$wavenumbers
# It was a string. Make it a number I guess.
wavenumbers <- as.numeric(wavenumbers)

thismatrix <- matrix(wavenumbers, nrow = 1, ncol = 1661)
length(subtracted)
newmatrix <- rbind(thismatrix, c(subtracted))

#Data_Frame <- data.frame (
#  wavelengths = c(wavenumbers),
#  spc = c(subtracted)
#)

# The docs give two different versions of how you are supposed to create a new hyperSpec object.
# This is the first, I don't know why they are using an equals sign, it's some sort of documentation shorthand?
# spc <- new("hyperSpec", spc = spectra.matrix, wavelength = wavelength.vector, data = extra.data)
# https://r-hyperspec.github.io/hyperSpec/articles/fileio.html#sec:read-mult-files

# this is the second,
# spc <- new("hyperSpec", spc, wavelength, data, labels)
# https://r-hyperspec.github.io/hyperSpec/articles/hyperSpec.html#sec:create

# So these are 2 different versions of the same manual with nearly identical URLS that state different things.

# str(wavenumbers)
# wavenumbers
# typeof(wavenumbers)

# the new("hyperSpec") doesn't accept atomic vectors.
# wavenumbers <- list(wavenumbers)

# data frame seems accepted by new, but I see all these V characters?
# wavenumbers <- as.data.frame(wavenumbers)
wavenumbers

#newmatrix <- t(newmatrix)

#thismatrix <- t(thismatrix)

newmatrix
spec <- new("hyperSpec", subtracted, NULL, wavenumbers, NULL)

# > spec <- new("hyperSpec", newmatrix, wavenumbers, NULL, NULL)
# 
# Error in if (nrow(data) == 1 && nrow(spc) > 1) data <- data[rep(1, nrow(spc)),  : 
#                                                               missing value where TRUE/FALSE needed
#                                                             > spec <- new("hyperSpec", newmatrix, wavenumbers, newmatrix, NULL)
#                                                             Error in (function (cl, name, valueClass)  : 
#                                                                         c("assignment of an object of class “matrix” is not valid for @‘wavelength’ in an object of class “hyperSpec”; is(value, \"numeric\") is not TRUE", "assignment of an object of class “array” is not valid for @‘wavelength’ in an object of class “hyperSpec”; is(value, \"numeric\") is not TRUE")

# This looks to me like it is complaining that I'm submitting a matrix for wavelengths. 
# However, that slot is supposed to be for data, according to the documentation.
# The code in the github repo shows, 
# hyperSpec <- function(spc = NULL, data = NULL, wavelength = NULL,
#                       labels = NULL, gc = hy_get_option("gc"),
#                       log = "ignored") {
# initialize(spec, spc = thismatrix)

# So that's not the same. The docs show the order as spc, wavelength, data. The code shows that it should come in as spc, data, wavelength!

# The code actually runs without complaint up to this point. But all it charts is a diagonal line.


str(spec)
plot(spec)
str(spec)
baseline <- spc.rubberband(spc)

