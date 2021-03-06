//+------------------------------------------------------------------+
//|                                                          Env.mqh |
//|                                 Copyright 2017, Keisuke Iwabuchi |
//|                                        https://order-button.com/ |
//+------------------------------------------------------------------+


/**
 * 環境ファイルの読み込み、ファイルから値との取り出しをおこなう
 *
 * bool型は専用のgetBoolValueメソッドを使用すること。
 * color型はclrRedのように記述する必要あり。redだとダメ。
 * datetime型はyyyy.mm.dd HH:ii:ss形式で記述する必要あり。
 */


#ifndef _LOAD_MODULE_ENV
#define _LOAD_MODULE_ENV


/** Include header files */
#include <mql4_modules\Env\defines.mqh>
#include <mql4_modules\SymbolSearch\SymbolSearch.mqh>


/** 環境設定ファイルを取り扱うクラス */
class Env
{
   private:
      static string rows[];
      
      static bool loadSymbol(const string symbol);

   public:
      static bool loadEnvFile(const string file);
      
      template <typename T>
      static T get(const string name, T default_value = NULL);
      static bool getBoolValue(const string name, bool default_value = false);
};


/** @var string rows[] 読み込んだ環境ファイルを行毎に保存しておく配列 */
static string Env::rows[] = {};


/**
 * 取引銘柄を気配値表示に存在するか確認する。
 * 無ければ追加する
 *
 * @param const string symbol 対象となる銘柄名
 * 
 * @return bool true:成功, false:失敗
 */
static bool Env::loadSymbol(const string symbol)
{
   return(StringLen(SymbolSearch::getSymbolInMarket(symbol)) > 0);
}


/**
 * 指定の環境ファイルを読み込む
 *
 * @param const string file 環境ファイル名
 * 
 * @return bool true:成功, false:失敗
 */
static bool Env::loadEnvFile(const string file)
{
   string value     = "";
   int    str_size  = 0;
   int    row       = 0;
   int    handle    = FileOpen(file, FILE_READ|FILE_TXT);
   string symbol    = "";
   
   if(handle == INVALID_HANDLE) return(false);
   
   while(!FileIsEnding(handle)) {
      /** read the next row */
      str_size = FileReadInteger(handle, INT_VALUE);
      
      /** check the comment */
      value = FileReadString(handle, str_size);
      if(StringSubstr(value, 0, 1) == "#") continue;
      
      /** check '=' */
      if(StringFind(value, "=") == -1) continue;
      
      /** add value to Env::rows */
      ArrayResize(Env::rows, row + 1, 0);
      Env::rows[row] = value;
      row++;
   }
   
   FileClose(handle);
   
   /** 通貨ペアを気配値表示に追加する */
   symbol = Env::get<string>("SYMBOL");
   if(StringLen(symbol) > 0 && symbol != _Symbol) {
      if(!Env::loadSymbol(symbol)) return(false);
   }
   
   return(true);
}


/**
 * キーワードに対応した値を取り出す
 *
 * @param const string name 取得する値のキー
 * @param typename default_value 値やキーが存在しない場合の初期値
 *
 * @return typename キーに対応する値
 */
template <typename T>
static T Env::get(const string name, T default_value = NULL)
{
   int    size  = 0;
   string key   = "";
   string value = "";
   
   size = ArraySize(Env::rows);
   for(int i = 0; i < size; i++) {
      key = StringSubstr(Env::rows[i], 0, StringLen(name));
      if(key != name) continue;
      
      if(StringLen(Env::rows[i]) <= StringLen(name) + 1) return(default_value);
      
      value = StringSubstr(Env::rows[i], StringLen(name) + 1);
      return((T)value);
   }
   
   return(default_value);
}


/**
 * キーワードに対応した値を取り出す
 * string型をbool型に変換できない関係でgetメソッドをオーバーライド
 *
 * @param const string name 取得する値のキー
 * @param bool default_value 値やキーが存在しない場合の初期値
 *
 * @return bool キーに対応する値
 */
static bool Env::getBoolValue(const string name, bool default_value = false)
{
   int    size  = 0;
   string key   = "";
   string value = "";
   
   size = ArraySize(Env::rows);
   for(int i = 0; i < size; i++) {
      key = StringSubstr(Env::rows[i], 0, StringLen(name));
      if(key != name) continue;
      
      if(StringLen(Env::rows[i]) <= StringLen(name) + 1) return(default_value);
      
      value = StringSubstr(Env::rows[i], StringLen(name) + 1);
      
      if(StringCompare(value,"true",false) == 0 || 
         StringToInteger(value) != 0) {
         return(true);
      }
      return(false);
   }
   
   return(default_value);
}


#endif
