import 'dart:math';

import 'package:flutter/material.dart';

import 'package:candlesticks/src/constant/scales.dart';
import 'package:candlesticks/src/constant/view_constants.dart';
import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/widgets/candle_info_text.dart';
import 'package:candlesticks/src/widgets/candle_stick_widget.dart';
import 'package:candlesticks/src/widgets/interval_bar.dart';
import 'package:candlesticks/src/widgets/time_row.dart';

import '../models/candle.dart';
import 'dash_line.dart';

/// This widget manages gestures
/// Calculates the highest and lowest price of visible candles.
/// Updates right-hand side numbers.
/// And pass values down to [CandleStickWidget].
class MobileChart extends StatefulWidget {
  /// onScaleUpdate callback
  /// called when user scales chart using buttons or scale gesture

  /// onHorizontalDragUpdate
  /// callback calls when user scrolls horizontally along the chart
  final Function onHorizontalDragUpdate;

  /// candleWidth controls the width of the single candles.
  /// range: [2...10]
  final double candleWidth;

  /// list of all candles to display in chart
  final List<Candle> candles;

  /// index of the newest candle to be displayed
  /// changes when user scrolls along the chart
  final int index;

  final void Function(double) onPanDown;
  final void Function() onPanEnd;

  final void Function(String) onIntervalChange;
  final List<String> intervals;

  MobileChart({
    Key? key,
    required this.onHorizontalDragUpdate,
    required this.candleWidth,
    required this.candles,
    required this.index,
    required this.onPanDown,
    required this.onPanEnd,
    required this.onIntervalChange,
    required this.intervals,
  }) : super(key: key);

  @override
  State<MobileChart> createState() => _MobileChartState();
}

class _MobileChartState extends State<MobileChart> {
  double? longPressX;
  double? longPressY;
  double additionalVerticalPadding = 0;

  double calcutePriceScale(double height, double high, double low) {
    for (int i = 0; i < scales.length; i++) {
      double newHigh = (high ~/ scales[i] + 1) * scales[i];
      double newLow = (low ~/ scales[i]) * scales[i];
      double range = newHigh - newLow;
      if (height / (range / scales[i]) > MIN_PRICETILE_HEIGHT) {
        return scales[i];
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // determine charts width and height
        final double maxWidth = constraints.maxWidth - PRICE_BAR_WIDTH;
        // final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight - DATE_BAR_HEIGHT;

        // visible candles start and end indexes
        final int candlesStartIndex = max(widget.index, 0);
        final int candlesEndIndex = min(
            maxWidth ~/ widget.candleWidth + widget.index,
            widget.candles.length - 1);

        // visible candles highest and lowest price
        double candlesHighPrice = 0;
        double candlesLowPrice = double.infinity;
        for (int i = candlesStartIndex; i <= candlesEndIndex; i++) {
          candlesLowPrice = min(widget.candles[i].low, candlesLowPrice);
          candlesHighPrice = max(widget.candles[i].high, candlesHighPrice);
        }

        additionalVerticalPadding =
            min(maxHeight / 4, additionalVerticalPadding);
        additionalVerticalPadding = max(0, additionalVerticalPadding);

        // calcute priceScale
        double chartHeight = maxHeight * 0.75 -
            2 * (MAIN_CHART_VERTICAL_PADDING + additionalVerticalPadding);
        double priceScale =
            calcutePriceScale(chartHeight, candlesHighPrice, candlesLowPrice);

        // high and low calibrations revision
        candlesHighPrice = (candlesHighPrice ~/ priceScale + 1) * priceScale;
        candlesLowPrice = (candlesLowPrice ~/ priceScale) * priceScale;

        // calcute highest volume
        double volumeHigh = 0;
        for (int i = candlesStartIndex; i <= candlesEndIndex; i++) {
          volumeHigh = max(widget.candles[i].volume, volumeHigh);
        }

        if (longPressX != null && longPressY != null) {
          longPressX = max(longPressX!, 0);
          longPressX = min(longPressX!, maxWidth);
          longPressY = max(longPressY!, 0);
          longPressX = min(longPressX!, maxHeight);
        }

        return TweenAnimationBuilder(
          tween: Tween(begin: candlesLowPrice, end: candlesHighPrice),
          duration: Duration(milliseconds: 200),
          builder: (context, double high, _) {
            return TweenAnimationBuilder(
              tween: Tween(begin: candlesHighPrice, end: candlesLowPrice),
              duration: Duration(milliseconds: 200),
              builder: (context, double low, _) {
                final currentCandle = longPressX == null
                    ? null
                    : widget.candles[min(
                        max(
                            (maxWidth - longPressX!) ~/ widget.candleWidth +
                                widget.index,
                            0),
                        widget.candles.length - 1)];
                return Container(
                  color: Theme.of(context).background,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Stack(
                          children: [
                            TimeRow(
                              indicatorX: longPressX,
                              candles: widget.candles,
                              candleWidth: widget.candleWidth,
                              indicatorTime: currentCandle?.date,
                              index: widget.index,
                            ),
                            Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          child: AnimatedPadding(
                                            duration:
                                                Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    MAIN_CHART_VERTICAL_PADDING +
                                                        additionalVerticalPadding),
                                            child: RepaintBoundary(
                                              child: CandleStickWidget(
                                                candles: widget.candles,
                                                candleWidth:
                                                    widget.candleWidth,
                                                index: widget.index,
                                                high: high,
                                                low: low,
                                                bearColor:
                                                    Theme.of(context)
                                                        .primaryRed,
                                                bullColor:
                                                    Theme.of(context)
                                                        .primaryGreen,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // longPressY != null
                            //     ? Positioned(
                            //         top: longPressY! - 10,
                            //         child: Row(
                            //           children: [
                            //             // DashLine(
                            //             //   length: maxWidth,
                            //             //   color: Theme.of(context).grayColor,
                            //             //   direction: Axis.horizontal,
                            //             //   thickness: 0.5,
                            //             // ),
                            //             // Container(
                            //             //   color: Theme.of(context)
                            //             //       .hoverIndicatorBackgroundColor,
                            //             //   child: Center(
                            //             //     child: Text(
                            //             //       longPressY! < maxHeight * 0.75
                            //             //           ? HelperFunctions.priceToString(
                            //             //               high -
                            //             //                   (longPressY! - 20) /
                            //             //                       (maxHeight * 0.75 -
                            //             //                           40) *
                            //             //                       (high - low))
                            //             //           : HelperFunctions.addMetricPrefix(
                            //             //               HelperFunctions.getRoof(
                            //             //                       volumeHigh) *
                            //             //                   (1 -
                            //             //                       (longPressY! -
                            //             //                               maxHeight *
                            //             //                                   0.75 -
                            //             //                               10) /
                            //             //                           (maxHeight * 0.25 -
                            //             //                               10))),
                            //             //       style: TextStyle(
                            //             //         color: Theme.of(context)
                            //             //             .hoverIndicatorTextColor,
                            //             //         fontSize: 12,
                            //             //       ),
                            //             //     ),
                            //             //   ),
                            //             //   width: 50,
                            //             //   height: 20,
                            //             // ),
                            //           ],
                            //         ),
                            //       )
                            //     : Container(),
                            longPressX != null
                                ? Positioned(
                                    child: Container(
                                      width: widget.candleWidth,
                                      height: maxHeight,
                                      child: Center(
                                        child: DashLine(
                                          length: maxHeight,
                                          color: Theme.of(context).grayColor,
                                          direction: Axis.vertical,
                                          thickness: 1.0,
                                        ),
                                      ),
                                    ),

                                    right: (maxWidth - longPressX!) ~/
                                            widget.candleWidth *
                                            widget.candleWidth +
                                        PRICE_BAR_WIDTH,
                                  )
                                : Container(),

                            /// Candle Information is displayed in the below widget
                            currentCandle != null
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24, horizontal: 24),
                                    child:
                                        CandleInfoText(candle: currentCandle),
                                  )
                                : Container(),
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 0, bottom: 20),
                              child: GestureDetector(
                                onTapDown: (TapDownDetails details) {
                                  setState(() {
                                    longPressX = details.localPosition.dx;
                                    longPressY = details.localPosition.dy;
                                  });
                                },
                                onTapUp: (TapUpDetails details) {
                                  setState(() {
                                    longPressX = null;
                                    longPressY = null;
                                  });
                                },
                                onTapCancel: () {
                                  setState(() {
                                    longPressX = null;
                                    longPressY = null;
                                  });
                                },
                                onHorizontalDragStart:
                                    (DragStartDetails details) {
                                  setState(() {
                                    longPressX = details.localPosition.dx;
                                    longPressY = details.localPosition.dy;
                                  });
                                },
                                onHorizontalDragUpdate:
                                    (DragUpdateDetails details) {
                                  setState(() {
                                    longPressX = details.localPosition.dx;
                                    longPressY = details.localPosition.dy;
                                  });
                                },
                                behavior: HitTestBehavior.translucent,
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IntervalBar(
                            onIntervalChange: widget.onIntervalChange,
                            intervals: widget.intervals),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
