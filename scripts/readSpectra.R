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

# After a few days of trying I can see that the problem was a glaring mistake that appears twice in the hyperSpec documentation.
# It mixes up the order of the arguments provided to new() when making a hyperSpec object.
# I solved this by reading the code on gitHub - good warning I guess that you can't trust the docs and it's better to read the code.

require(hyperSpec)
wavenumbers <- meas_1$sc_sample$wavenumbers
spec <- new("hyperSpec", subtracted, NULL, rev(wavenumbers), NULL)

str(spec)
plot(spec)

# I'm using v 0.100.2 
# You're supposed to initialize objects even though it does work to plot without doing so.
# baseline fitting is complaining that spec is not a hyperSpec object (I think) so lets try initializing

#initialize(.Object, spc = NULL, data = NULL, wavelength = NULL, labels = NULL)
#spec2 <- new("hyperSpec")
#initialize(spec2, spec, NULL, NULL, NULL)

bl <- spc.rubberband(spec)
str(bl)
plot(spec)
plot(spec-bl)
plot(bl)
