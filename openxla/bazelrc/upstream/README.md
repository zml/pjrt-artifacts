# upstream .bazerlc

Tensorflow.bazelrc makes toolchain assumption when compiling "from" an platform.
So we replace it with a sanitized version of the base options without those assumptions...

And we replace the .bazerlc with our custom options
