/*****************************************************************************
 * Project:  LibCMaker
 * Purpose:  A CMake build scripts for build libraries with CMake
 * Author:   NikitaFeodonit, nfeodonit@yandex.com
 *****************************************************************************
 *   Copyright (c) 2017-2022 NikitaFeodonit
 *
 *    This file is part of the LibCMaker project.
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published
 *    by the Free Software Foundation, either version 3 of the License,
 *    or (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *    See the GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program. If not, see <http://www.gnu.org/licenses/>.
 ****************************************************************************/

#include "include/core/SkCanvas.h"
#include "include/core/SkRRect.h"
#include "include/core/SkSurface.h"
#include "modules/skshaper/include/SkShaper.h"
#include "modules/skunicode/include/SkUnicode.h"

#include "FileUtil.h"

#include <vector>

#include "gtest/gtest.h"

// https://stackoverflow.com/a/5920028
#if __APPLE__
    #include <string.h>
    #include <TargetConditionals.h>

    #if TARGET_IPHONE_SIMULATOR
      // iOS Simulator
      #include <CoreFoundation/CFBundle.h>
    #elif TARGET_OS_IPHONE
      // iOS device
    #elif TARGET_OS_MAC
      // Other kinds of Mac OS
    #else
    #   error "Unknown Apple platform"
    #endif
#endif


// https://stackoverflow.com/a/5920028
#if __APPLE__
  //#include <TargetConditionals.h>
  #if TARGET_IPHONE_SIMULATOR
    // iOS Simulator

    // https://stackoverflow.com/a/67022872
    std::string get_resources_dir()
    {
      CFURLRef resourceURL = CFBundleCopyResourcesDirectoryURL(CFBundleGetMainBundle());
      char resourcePath[PATH_MAX];

      if (CFURLGetFileSystemRepresentation(resourceURL, true, (UInt8 *)resourcePath, PATH_MAX))
      {
        if (resourceURL != NULL)
        {
          CFRelease(resourceURL);
        }
        return resourcePath;
      }
    }
  #endif
#endif  // __APPLE__


TEST(Examle, test)
{
  std::string resDir;
  std::string workDir;

  // https://stackoverflow.com/a/5920028
  #if __APPLE__
    //#include <TargetConditionals.h>
    #if TARGET_IPHONE_SIMULATOR
      // iOS Simulator

      resDir = get_resources_dir() + "/";

      // https://stackoverflow.com/a/39022407
      // HOME is the home directory of your application
      // points to the root of your sandbox.
      std::string homeDir = getenv("HOME");
      workDir = homeDir + "/Documents/";
    #endif
  #endif  // __APPLE__

  enum
  {
    BYTES_PER_PIXEL = 4
  };

  const int frameWidth = 770;
  const int frameHeight = 370;
  const int stride = frameWidth * BYTES_PER_PIXEL;

  SkColorType colorType = SkColorType::kRGB_888x_SkColorType;
  SkAlphaType alphaType = SkAlphaType::kOpaque_SkAlphaType;

  SkImageInfo imageInfo = SkImageInfo::Make(
    frameWidth, frameHeight, colorType, alphaType);
  sk_sp<SkSurface> surface = SkSurface::MakeRaster(imageInfo);
  SkCanvas* canvas = surface->getCanvas();

  canvas->drawColor(SK_ColorWHITE);

  SkPaint paint;
  paint.setStyle(SkPaint::kFill_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(4);
  paint.setColor(0xff4285F4);

  SkRect rect = SkRect::MakeXYWH(10, 10, 100, 160);
  canvas->drawRect(rect, paint);

  SkRRect oval;
  oval.setOval(rect);
  oval.offset(40, 80);
  paint.setColor(0xffDB4437);
  canvas->drawRRect(oval, paint);

  paint.setColor(0xff0F9D58);
  canvas->drawCircle(180, 50, 25, paint);

  rect.offset(80, 50);
  paint.setColor(0xffF4B400);
  paint.setStyle(SkPaint::kStroke_Style);
  canvas->drawRoundRect(rect, 10, 10, paint);


  // Text samples

  struct SampleData {
    std::string lang;
    std::string font;
    std::string text;
  };

  std::vector<SampleData> samples = {
    // "Christmas is celebrated in a French garden" (french)
    // "Noël se fête dans un jardin à la française"
    {"french", "Tinos-Regular.ttf", "Noël fête à française"},
    // Ligatures (french)
    //{"french", "Tinos-Regular.ttf", "fffffi. VAV."},
    // "The storm covers the sky with mist" (russian)
    {"russian", "Tinos-Regular.ttf", "Бу́ря мгло́ю не́бо кро́ет"},
    // "When I went to the library" (arabic)
    {"arabic", "amiri-regular.ttf", "عندما ذهبت إلى المكتبة"},
    // "boys are reading this book" (hindi)
    {"hindi", "Sanskrit2003.ttf", "लड़के इस किताब को पड़ रहे हैं"}
    // "This is my home" (chinese)
    //{"chinese", "fireflysung.ttf", "這是我的家"}
  };

  SkScalar fontSize = 50;
  SkScalar lineHight = fontSize + 30;
  SkScalar margin = 20;

  paint.setColor(0xff000000);
  paint.setStyle(SkPaint::kFill_Style);

  auto unicode = SkUnicode::Make();
  ASSERT_TRUE(unicode)
    << "Check if file 'icudtl.dat' exists in the folder with exe-file of test.";

  int yLine = 0;

  for (const auto& sample : samples) {
    sk_sp<SkFontMgr> fontMgr = SkFontMgr::RefDefault();
    std::string fontFile = resDir + sample.font;
    sk_sp<SkTypeface> typeface = fontMgr->makeFromFile(fontFile.c_str());

    std::unique_ptr<SkShaper> shaper = SkShaper::Make(fontMgr);
    //SkShaper::PurgeCaches();  // NOTE: usefull in loop?

    SkFont srcFont{typeface};
    srcFont.setSize(fontSize);
    srcFont.setEdging(SkFont::Edging::kSubpixelAntiAlias);
    srcFont.setSubpixel(true);

    size_t len = strlen(sample.text.c_str());

    std::unique_ptr<SkShaper::LanguageRunIterator> language(
        SkShaper::MakeStdLanguageRunIterator(sample.text.c_str(), len));
    ASSERT_TRUE(language);

    std::unique_ptr<SkShaper::FontRunIterator> fontRunIt(
      SkShaper::MakeFontMgrRunIterator(
        sample.text.c_str(), len, srcFont, fontMgr, "FontFamilie",
        SkFontStyle::Normal(), &*language));
    ASSERT_TRUE(fontRunIt);

    std::unique_ptr<SkShaper::BiDiRunIterator> bidi(
        SkShaper::MakeBiDiRunIterator(sample.text.c_str(), len, 0xfe));
    ASSERT_TRUE(bidi);

    SkFourByteTag undeterminedScript = SkSetFourByteTag('Z','y','y','y');
    std::unique_ptr<SkShaper::ScriptRunIterator> script(
        SkShaper::MakeScriptRunIterator(sample.text.c_str(), len,
        undeterminedScript));
    ASSERT_TRUE(script);

    SkTextBlobBuilderRunHandler builder(sample.text.c_str(), {margin, margin});

    shaper->shape(
      sample.text.c_str(), len, *fontRunIt, *bidi, *script, *language, 2000,
      &builder);

    canvas->drawTextBlob(builder.makeBlob(), 210, yLine, paint);
    yLine += lineHight;
  }


  std::vector<unsigned char> frameBuf(
      static_cast<unsigned int>(std::abs(stride * frameHeight)));
  SkImageInfo dstInfo = SkImageInfo::Make(
    frameWidth, frameHeight, colorType, alphaType);
  EXPECT_TRUE(canvas->readPixels(dstInfo, frameBuf.data(),
    dstInfo.width() * BYTES_PER_PIXEL, 0, 0));


  // Write our picture to file.
  std::string fileOutTest1 = workDir + "Skia_draw.ppm";
  writePpmFile(
      frameBuf.data(), frameWidth, frameHeight, BYTES_PER_PIXEL, fileOutTest1);

  // Compare our file with prototype.
  std::string fileTest1 = resDir + "Skia_draw_test_sample.ppm";
  EXPECT_TRUE(compareFiles(fileTest1, fileOutTest1));
}
