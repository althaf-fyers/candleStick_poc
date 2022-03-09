import 'package:candlesticks/src/theme/theme_data.dart';
import 'package:candlesticks/src/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class IntervalBar extends StatefulWidget {
  const IntervalBar({
    Key? key,
    required this.onIntervalChange,
    required this.intervals,
  }) : super(key: key);

  final void Function(String) onIntervalChange;
  final List<String> intervals;

  @override
  _IntervalBarState createState() => _IntervalBarState();
}

class _IntervalBarState extends State<IntervalBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        itemCount: widget.intervals.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: CustomButton(
                width: 50.0,
                color: Theme.of(context).lightGold,
                child: Text(widget.intervals[index],
                    style: TextStyle(
                      color: Theme.of(context).gold,
                    )),
                onPressed: () =>
                    widget.onIntervalChange(widget.intervals[index])),
          );
        },
      ),
    );
  }
}
