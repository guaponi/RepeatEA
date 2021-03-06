//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                 Copyright 2017, Keisuke Iwabuchi |
//|                                        https://order-button.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Keisuke Iwabuchi"
#property link      "https://order-button.com/"
#property version "1.00"
#property strict


#ifndef _LOAD_MODULE_TRADE
#define _LOAD_MODULE_TRADE


/** Include header files. */
#include <mql4_modules\Trade\defines.mqh>
#include <mql4_modules\Trade\enums.mqh>
#include <mql4_modules\Trade\structs.mqh>
#include <mql4_modules\Env\Env.mqh>
#include <mql4_modules\Order\Order.mqh>
#include <mql4_modules\Price\Price.mqh>


/** Import library file */
#import "stdlib.ex4"
   string ErrorDescription(int error_code);
#import


/** Trade class. */
class Trade
{
   public:
      static bool Entry(OrderSendRequest &params);
      static bool Exit(OrderCloseRequest &params);
      static bool Modify(OrderModifyRequest &params);
      static bool Delete(OrderDeleteRequest &params);
   
   protected:
      static double   getSafeLots(double lots);
      static double   getSafePrice(TRADE_SIGNAL type,
                                   TradePrice &price);
      static int      getSafeSlippage(int slippage);
      static double   getSafeStopLoss(TRADE_SIGNAL type,
                                      TradePrice &stoploss);
      static double   getSafeTakeProfit(TRADE_SIGNAL type,
                                        TradePrice &takeprofit);
      static datetime getSafeExpiration(datetime expiration);
};


/**
 * Open market or place a pending order.
 *
 * @param OrderSendRequest &params  Parameters of OrderSend function.
 *
 * @return bool  Returns true if successful, otherwise false.
 */
bool Trade::Entry(OrderSendRequest &params)
{
   int ticket     = -1;
   int count      = 0;
   int error_code = 0;

   while(ticket == -1) {
      ticket = OrderSend(
         __Symbol,
         params.type,
         Trade::getSafeLots(params.lots),
         Trade::getSafePrice(params.type, params.price),
         Trade::getSafeSlippage(params.slippage),
         Trade::getSafeStopLoss(params.type, params.stoploss),
         Trade::getSafeTakeProfit(params.type, params.takeprofit),
         params.comment,
         params.magic,
         Trade::getSafeExpiration(params.expiration),
         params.arrow
      );
      
      if(ticket != -1) break;
      
      /** error occurred */
      error_code = _LastError;
      Print(ErrorDescription(error_code), " ErrorCode=", error_code);
      
      if(IsTesting()) return(false);
      switch(error_code) {
         case ERR_INVALID_STOPS:               return(false); break;
         case ERR_INVALID_TRADE_VOLUME:        return(false); break;
         case ERR_NOT_ENOUGH_MONEY:            return(false); break;
         case ERR_LONG_POSITIONS_ONLY_ALLOWED: return(false); break;
         case ERR_TRADE_EXPIRATION_DENIED:     return(false); break;
         case ERR_TRADE_TOO_MANY_ORDERS:       return(false); break;
         case ERR_TRADE_HEDGE_PROHIBITED:      return(false); break;
      }
   
      count++;
      if(count > RETRY_MAX) break;
      Sleep(RETRY_INTERVAL);
   }
   
   return(ticket != -1);
}


/**
 * Closes opened order.
 *
 * @param OrderCloseRequest &params  Parameters of OrderClose function.
 *
 * @return bool  Returns true if successful, otherwise false.
 */
bool Trade::Exit(OrderCloseRequest &params)
{
   bool result     = false;
   int  count      = 0;
   int  error_code = 0;
   
   while(result == false) {
      result = OrderClose(
         params.ticket,
         params.lots,
         params.price,
         Trade::getSafeSlippage(params.slippage),
         params.arrow
      );
      
      if(result == true) break;
      
      /** error occurred */
      error_code = _LastError;
      Print(ErrorDescription(error_code), " ErrorCode=", error_code);
      
      if(IsTesting()) return(false);
      switch(error_code) {
         case ERR_INVALID_STOPS:         return(false); break;
         case ERR_INVALID_TRADE_VOLUME:  return(false); break;
         case ERR_TRADE_TOO_MANY_ORDERS: return(false); break;
      }
   
      count++;
      if(count > RETRY_MAX) break;
      Sleep(RETRY_INTERVAL);
   }
   
   return(result);
}


/**
 * Modification of characteristics of the previously opened or pending orders.
 *
 * @param OrderModifyRequest &params  Paramters of OrderModify function.
 *
 * @return bool  Returns true if successful, otherwise false.
 */
bool Trade::Modify(OrderModifyRequest &params)
{
   bool result     = false;
   int  count      = 0;
   int  error_code = 0;
   
   while(result == false) {
      result = OrderModify(
         params.ticket,
         params.price,
         params.stoploss,
         params.takeprofit,
         params.expiration,
         params.arrow
      );
      
      /** error occurred */
      error_code = _LastError;
      Print(ErrorDescription(error_code), " ErrorCode=", error_code);
      
      if(IsTesting()) return(false);
      switch(error_code) {
         case ERR_INVALID_STOPS:         return(false); break;
         case ERR_INVALID_TRADE_VOLUME:  return(false); break;
         case ERR_TRADE_TOO_MANY_ORDERS: return(false); break;
      }
   
      count++;
      if(count > RETRY_MAX) break;
      Sleep(RETRY_INTERVAL);
   }
   
   return(result);
}


/**
 * Deletes previously opned pending order.
 *
 * @param OrderDeleteRequest &params  Parameters of OrderDelete function.
 *
 * @return bool  Returns true if successful, otherwise false.
 */
bool Trade::Delete(OrderDeleteRequest &params)
{
   bool result     = false;
   int  count      = 0;
   int  error_code = 0;
   
   while(result == false) {
      result = OrderDelete(params.ticket, params.arrow);
      
      /** error occurred */
      error_code = _LastError;
      Print(ErrorDescription(error_code), " ErrorCode=", error_code);
      
      if(IsTesting()) return(false);
      switch(error_code) {
         case ERR_INVALID_STOPS:         return(false); break;
         case ERR_INVALID_TRADE_VOLUME:  return(false); break;
         case ERR_TRADE_TOO_MANY_ORDERS: return(false); break;
      }
   
      count++;
      if(count > RETRY_MAX) break;
      Sleep(RETRY_INTERVAL);
   }
   
   return(result);
}


/**
 * Normalize the lots to a value that can be ordered.
 *
 * @param static double  Number of lots.
 *
 * @return double  Number of lots normalized to an orderable value.
 */
static double Trade::getSafeLots(double lots)
{
   int    digits    = 0;
   int    remainder = 0;
   int    lots_int  = 0;
   double max       = MarketInfo(__Symbol, MODE_MAXLOT);
   double min       = MarketInfo(__Symbol, MODE_MINLOT);
   double step      = MarketInfo(__Symbol, MODE_LOTSTEP);

   while(step < 1) {
      step *= 10;
      digits++;
   }
   
   lots_int  = (int)(lots * MathPow(10, digits));
   remainder = lots_int % (int)MathFloor(step);
   if(remainder != 0) {
      lots = MarketInfo(__Symbol, MODE_LOTSTEP) * 
             MathFloor((lots_int - remainder) / (int)MathFloor(step));
   }
   
   if(lots > max) lots = max;
   if(lots < min) lots = min;
   
   return(NormalizeDouble(lots, digits));
}


/**
 * Normalize the price to a value that can be ordered.
 *
 * @param TRADE_SIGNAL type  Operation type.
 * @param TradePrice &price  TradePrice structure about order price.
 *
 * @return double  Price normalized to an orderable value.
 */
static double Trade::getSafePrice(TRADE_SIGNAL type, TradePrice &price)
{
   double result = 0;
   double ask    = MarketInfo(__Symbol, MODE_ASK);
   double bid    = MarketInfo(__Symbol, MODE_BID);
   
   switch(price.type) {
      case DYNAMIC_PRICE:
         if(type == BUY || type == BUY_LIMIT || type == BUY_STOP) {
            result = ask;
         }
         else if(type == SELL || type == SELL_LIMIT || type == SELL_STOP) {
            result = bid;
         }
         break;
      case DYNAMIC_PIPS:
         if(type == BUY || type == BUY_LIMIT || type == BUY_STOP) {
            result = ask + Price::PipsToPrice(price.value);
         }
         else if(type == SELL || type == SELL_LIMIT || type == SELL_STOP) {
            result = bid - Price::PipsToPrice(price.value);
         }
         break;
      case STATIC_PRICE:
         result = price.value;
         break;
   }
   
   return(NormalizeDouble(result, __Digits));
}


/**
 * Normalize the slippage to a value that can be ordered.
 *
 * @param int slippage  Maximu price slippage.
 *
 * @return int  Slippage normalized to an orderable value.
 */
static int Trade::getSafeSlippage(int slippage)
{
   return((slippage) ? 0 : slippage);
}


/**
 * Normalize the stop loss to a value that can be ordered.
 *
 * @param TRADE_SIGNAL type     Operation type.
 * @param TradePrice &stoploss  TradePrice structure about stop loss.
 *
 * @return double  Stop loss level normalized to an orderable value.
 */
static double Trade::getSafeStopLoss(TRADE_SIGNAL type, TradePrice &stoploss)
{
   double value        = 0;
   double difference   = 0;
   double stop_level   = MarketInfo(__Symbol, MODE_STOPLEVEL);
   double freeze_level = MarketInfo(__Symbol, MODE_FREEZELEVEL);
   double ask          = MarketInfo(__Symbol, MODE_ASK);
   double bid          = MarketInfo(__Symbol, MODE_BID);
   
   switch(stoploss.type) {
      case DYNAMIC_PIPS:
         if(type == BUY || type == BUY_LIMIT || type == BUY_STOP) {
            value = ask - Price::PipsToPrice(stoploss.value);
         }
         else if(type == SELL || type == SELL_LIMIT || type == SELL_STOP) {
            value = bid + Price::PipsToPrice(stoploss.value);
         }
         break;
      case STATIC_PRICE:
         value = stoploss.value;
         break;
   }
   
   if(type == BUY) {
      difference = ask - value;
      if(difference < stop_level)   value = ask - stop_level;
      if(difference < freeze_level) value = ask - freeze_level;
   }
   else if(type == SELL) {
      difference = value - bid;
      if(difference < stop_level)   value = bid + stop_level;
      if(difference < freeze_level) value = bid + freeze_level;
   }

   return(NormalizeDouble(value, __Digits));
}


/**
 * Normalize the take profit to a value that can be ordered.
 *
 * @param TRADE_SIGNAL type       Operation type.
 * @param TradePrice &takeprofit  TradePrice structure about take profit.
 *
 * @return double  Take profit level normalized to an orderable value.
 */
static double Trade::getSafeTakeProfit(TRADE_SIGNAL type,
                                       TradePrice &takeprofit)
{
   double value        = 0;
   double difference   = 0;
   double stop_level   = MarketInfo(__Symbol, MODE_STOPLEVEL);
   double freeze_level = MarketInfo(__Symbol, MODE_FREEZELEVEL);
   double ask          = MarketInfo(__Symbol, MODE_ASK);
   double bid          = MarketInfo(__Symbol, MODE_BID);
   
   switch(takeprofit.type) {
      case DYNAMIC_PIPS:
         if(type == BUY || type == BUY_LIMIT || type == BUY_STOP) {
            value = ask + Price::PipsToPrice(takeprofit.value);
         }
         else if(type == SELL || type == SELL_LIMIT || type == SELL_STOP) {
            value = bid - Price::PipsToPrice(takeprofit.value);
         }
         break;
      case STATIC_PRICE:
         value = takeprofit.value;
         break;
   }
   
   if(type == BUY) {
      difference = value - ask;
      if(difference < stop_level)   value = ask + stop_level;
      if(difference < freeze_level) value = ask + freeze_level;
   }
   else if(type == SELL) {
      difference = bid - value;
      if(difference < stop_level)   value = bid - stop_level;
      if(difference < freeze_level) value = bid - freeze_level;
   }
   
   return(NormalizeDouble(value, __Digits));
}


/**
 * Normalize the expiration time to a value that can be ordered.
 *
 * @param datetime expiration  Order expiration time.
 *
 * @return datetime  Expiration time normarized to an orderable value.
 */
static datetime Trade::getSafeExpiration(datetime expiration)
{
   return((expiration < 0) ? 0 : expiration);
}


#endif 
