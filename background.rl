#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <emscripten.h>

// TODO Bother to parse like HTML and CSS to extract data:// URIs i

%%{
  machine content_type;
  alphtype unsigned char;

  # sloppy ass

  OWS = [ \t]*;
  VCHAR = 0x21..0x7E;
  tchar = [!#$%&'*+-.^_`|~] | alnum;
  token = tchar+;
  obs_text = 0x80..0xFF;
  qdtext = [\t ] | 0x21 | 0x23..0x5B | 0x5D..0x7E | obs_text;
  quoted_pair = "\\" ([\t ] | VCHAR | obs_text);
  quoted_string = "\"" (qdtext | quoted_pair)* "\"";

  action exceed_zero { exceed = 0; }
  action exceed_inc { if (++exceed > 126) return NULL; }

  restricted_name = alnum (alnum | [\-!#$&^_.+])* >exceed_zero $exceed_inc;
  # https://www.rfc-editor.org/info/rfc6838/#section-4.2

  generic_mime_type = restricted_name "/" restricted_name;
  parameter_name = token;
  parameter_value = token | quoted_string;
  generic_parameter = parameter_name "=" parameter_value;
  generic_parameters = (OWS ";" OWS generic_parameter? )*;

  included_mime_type = "image/"i restricted_name
                     | "video/"i restricted_name
                     | "audio/"i restricted_name 
                     | "audio/aac"i       %{a = "aac";}
                     | "image/apng"i      %{a = "apng";}
                     | "image/avif"i      %{a = "avif";}
                     | "video/x-msvideo"i %{a = "avi";}
                     | "application/vnd.amazon.ebook"i %{a = "azw";}
                     | "image/bmp"i          %{a = "bmp";}
                     | "application/msword"i %{a = "doc";}
                     | "application/vnd.openxmlformats-officedocument.wordprocessingml.document"i %{a = "docx";}
                     | "application/epub+zip"i     %{a = "epub";}
                     | "image/gif"i                %{a = "gif";}
                     | "image/vnd.microsoft.icon"i %{a = "ico";}
                     | "image/jpeg"i      %{a = "jpg";}
                     | "audio/mp4"i       %{a = "m4a";}
                     | "audio/mpeg"i      %{a = "mp3";}
                     | "video/mp4"i       %{a = "mp4";}
                     | "video/mpeg"i      %{a = "mpeg";}
                     | "audio/ogg"i       %{a = "oga";} # or opus
                     | "video/ogg"i       %{a = "ogv";}
                     | "application/ogg"i %{a = "ogx";}
                     | "image/png"i       %{a = "png";}
                     | "application/pdf"i %{a = "pdf";}
                     | "application/vnd.ms-powerpoint"i %{a = "ppt";}
                     | "application/vnd.openxmlformats-officedocument.presentationml.presentation" %{a = "pptx";}
                     | "image/tiff"  %{a = "tiff";}
                     | "video/mp2t"  %{a = "ts";}
                     | "audio/wav"   %{a = "wav";}
                     | "audio/webm"  %{a = "weba";}
                     | "video/webm"  %{a = "webm";}
                     | "image/webp"  %{a = "webp";}
                     | "video/3gpp"  %{a = "3gp";}
                     | "audio/3gpp"  %{a = "3gp";}
                     | "video/3gpp2" %{a = "3g2";}
                     | "audio/3gpp2" %{a = "3g2";}
                     | "application/vnd.adobe.flash.movie" %{a = "swf";}
                     ;
  excluded_mime_type = "image/svg+xml";

  desired_mime_type = included_mime_type - excluded_mime_type;

  action acce
  {
    if (!a) a = "";
  }

  mime_type = (desired_mime_type %acce | generic_mime_type);

  action errr
  {
    printf("error on %c of %s in pos %d\n", fc, in, (int)(p - in));
    return NULL;
  }

  main2 = OWS mime_type generic_parameters OWS;
  main := (main2 ("," main2)?) $!errr;
}%%

EMSCRIPTEN_KEEPALIVE char * test_mime(unsigned char *in)
{
  int exceed, cs;
  char *a = NULL;
  size_t l = strlen((char *)in);
  unsigned char *p = in, *pe = p + l, *eof = pe;
  %% write data noerror nofinal noentry;
  %% write init;
  %% write exec;
  return a;
}

EM_JS(void,init,(void),{
  async function type(details)
  {
    try {
      const mime = details.responseHeaders
                          .findLast(h => 'content-type' === h.name.toLowerCase())?.value;

      if (!mime)
      {
        await browser.storage.session.set({ [details.requestId]: { acc: false }});
        return;
      }

      const ptr = stringToNewUTF8(mime);
      const is_copy = _test_mime(ptr);
      _free(ptr);

      if (!is_copy)
      {
        await browser.storage.session.set({ [details.requestId]: { acc: false }});
        return;
      }

      let ext = UTF8ToString(is_copy);
      if ("" === ext) try {
        ext = URL.parse(details.url).pathname.split('/')
                 .findLast(() => true).split('.')
                 .splice(1).join('.');
        if (!ext.length)
          ext = 'bin';
      }
      catch (e) { console.log(e); ext = "bin"; }

      await browser.storage.session.set({ [details.requestId]: { acc: true, ext }});
    }
    catch (e) {
      console.log(e);
      for (let keep = true; keep; )
        try {
          await browser.storage.session.set({ [details.requestId]: { acc: false }});
          keep = false;
        }
        catch (er) { console.log(er); }
    }
  }

  async function record(d) {
    try {
      const i = d.requestId;
      const f = browser.webRequest.filterResponseData(i);
      const n = Uint8Array.from(i).toBase64({alphabet: 'base64url', omitPadding: true});
      const bs = [];
      f.ondata = (e) => {
        f.write(e.data);
        bs.push(e.data);
      };
      f.onstop = async (e) => {
        f.close();

        let pussy = {};

        for (let rep = 0; rep < 50000 && !(i in pussy); rep++) // XXX
          pussy = await browser.storage.session.get(i);

        if (!(i in pussy) || !pussy[i].acc)
          return;

        let once = false;
        for (let j = 0; j < bs.length; j++)
        {
          const op = once ? 'a' : 'w';
          once = true;
          const p = (new Uint8Array(bs[j])).toBase64();
          const m = String.prototype.concat(op,n,'.',pussy[i]?.ext ?? 'bin',',',p);
          console.assert(JSON.stringify(m).length < 2**32);
          const r = await browser.runtime.sendNativeMessage('ping_pong',m);
        }
      };
      f.onerror = async (e) => {
        for (let keep = true; keep; )
          try {
            await browser.storage.session.set({ [i]: { acc: false }});
            keep = false;
          }
          catch (er) { console.log(er); }
      };
    }
    catch (e) { console.log(e); }
  }

  browser.webRequest.onHeadersReceived.addListener(type, {
    urls: ['<all_urls>'],
  },['responseHeaders']);
  browser.webRequest.onBeforeRequest.addListener(record, {
    urls: ['<all_urls>']
  },['blocking']); 
});

int main(void)
{
  init();
  return 0;
}
