#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif


#include <google/vcdecoder.h>
#include <google/vcencoder.h>

MODULE = Vcdiff        PACKAGE = Vcdiff
 
PROTOTYPES: DISABLE
 
SV *
encode_string(source, target)
        SV *source
        SV *target
    CODE:
        const char *source_p, *target_p;
        size_t source_size, target_size;
        std::string output_string;

        source_size = SvCUR(source);
        source_p = SvPV(source, source_size);
        target_size = SvCUR(target);
        target_p = SvPV(target, target_size);

        open_vcdiff::VCDiffEncoder encoder(source_p, source_size);

        if (!encoder.Encode(target_p, target_size, &output_string)) {
          croak("open_vcdiff::VCDiffEncoder::Encode() returned false");
        }

        RETVAL = newSVpv(output_string.c_str(), output_string.length());

    OUTPUT:
        RETVAL



SV *
decode_string(source, delta)
        SV *source
        SV *delta
    CODE:
        const char *source_p, *delta_p;
        size_t source_size, delta_size;
        std::string output_string;

        source_size = SvCUR(source);
        source_p = SvPV(source, source_size);
        delta_size = SvCUR(delta);
        delta_p = SvPV(delta, delta_size);

        std::string delta_string(delta_p, delta_size);

        open_vcdiff::VCDiffDecoder decoder;

        if (!decoder.Decode(source_p, source_size, delta_string, &output_string)) {
          croak("open_vcdiff::VCDiffDecoder::Decode() returned false");
        }

        RETVAL = newSVpv(output_string.c_str(), output_string.length());

    OUTPUT:
        RETVAL
