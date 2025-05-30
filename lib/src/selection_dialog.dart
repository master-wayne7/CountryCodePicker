import 'package:flutter/material.dart';

import 'country_code.dart';
import 'country_localizations.dart';

/// selection dialog used for selection of the country code
class SelectionDialog extends StatefulWidget {
  final List<CountryCode> elements;
  final bool? showCountryOnly;
  final InputDecoration searchDecoration;
  final TextStyle? searchStyle;
  final TextStyle? textStyle;
  final BoxDecoration? boxDecoration;
  final WidgetBuilder? emptySearchBuilder;
  final bool? showFlag;
  final double flagWidth;
  final Decoration? flagDecoration;
  final Size? size;
  final bool hideSearch;
  final bool hideCloseIcon;
  final Icon? closeIcon;

  /// Background color of SelectionDialog
  final Color? backgroundColor;

  /// Boxshaow color of SelectionDialog that matches CountryCodePicker barrier color
  final Color? barrierColor;

  /// elements passed as favorite
  final List<CountryCode> favoriteElements;

  final EdgeInsetsGeometry dialogItemPadding;

  final EdgeInsetsGeometry searchPadding;

  SelectionDialog(
    this.elements,
    this.favoriteElements, {
    Key? key,
    this.showCountryOnly,
    this.emptySearchBuilder,
    InputDecoration searchDecoration = const InputDecoration(),
    this.searchStyle,
    this.textStyle,
    this.boxDecoration,
    this.showFlag,
    this.flagDecoration,
    this.flagWidth = 32,
    this.size,
    this.backgroundColor,
    this.barrierColor,
    this.hideSearch = false,
    this.hideCloseIcon = false,
    this.closeIcon,
    this.dialogItemPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.searchPadding = const EdgeInsets.symmetric(horizontal: 24),
  })  : searchDecoration = searchDecoration.prefixIcon == null ? searchDecoration.copyWith(prefixIcon: const Icon(Icons.search)) : searchDecoration,
        super(key: key);

  @override
  State<StatefulWidget> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  /// this is useful for filtering purpose
  late List<CountryCode> filteredElements;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          clipBehavior: Clip.hardEdge,
          width: widget.size?.width ?? MediaQuery.of(context).size.width,
          height: widget.size?.height ?? MediaQuery.of(context).size.height * 0.85,
          decoration: widget.boxDecoration ??
              BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                boxShadow: [
                  BoxShadow(
                    color: widget.barrierColor ?? Colors.grey.withOpacity(1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.hideCloseIcon)
                IconButton(
                  padding: const EdgeInsets.all(0),
                  iconSize: 20,
                  icon: widget.closeIcon!,
                  onPressed: () => Navigator.pop(context),
                ),
              if (!widget.hideSearch)
                Padding(
                  padding: widget.searchPadding,
                  child: TextField(
                    controller: _searchController,
                    style: widget.searchStyle,
                    decoration: widget.searchDecoration,
                    onChanged: _filterElements,
                  ),
                ),
              Expanded(
                child: ListView(
                  children: [
                    ListenableBuilder(
                      listenable: _searchController,
                      builder: (context, child) {
                        if (_searchController.text.isNotEmpty) {
                          return const SizedBox();
                        }
                        return widget.favoriteElements.isEmpty
                            ? const DecoratedBox(decoration: BoxDecoration())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...widget.favoriteElements.map(
                                    (f) => InkWell(
                                      onTap: () {
                                        _selectItem(f);
                                      },
                                      child: Padding(
                                        padding: widget.dialogItemPadding,
                                        child: _buildOption(f),
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                ],
                              );
                      },
                    ),
                    if (filteredElements.isEmpty)
                      _buildEmptySearchWidget(context)
                    else
                      ...filteredElements.map((e) => InkWell(
                          onTap: () {
                            _selectItem(e);
                          },
                          child: Padding(
                            padding: widget.dialogItemPadding,
                            child: _buildOption(e),
                          ))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildOption(CountryCode e) {
    return SizedBox(
      width: 400,
      child: Flex(
        direction: Axis.horizontal,
        children: <Widget>[
          if (widget.showFlag!)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: widget.flagDecoration,
                clipBehavior: widget.flagDecoration == null ? Clip.none : Clip.hardEdge,
                child: Image.asset(
                  e.flagUri!,
                  package: 'country_code_picker',
                  width: widget.flagWidth,
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: widget.showCountryOnly!
                ? Text(
                    e.toCountryStringOnly(),
                    overflow: TextOverflow.fade,
                    style: widget.textStyle,
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 47,
                        child: Text(
                          e.toString(),
                          overflow: TextOverflow.fade,
                          style: widget.textStyle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          e.toCountryStringOnly(),
                          overflow: TextOverflow.fade,
                          style: widget.textStyle,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchWidget(BuildContext context) {
    if (widget.emptySearchBuilder != null) {
      return widget.emptySearchBuilder!(context);
    }

    return Center(
      child: Text(CountryLocalizations.of(context)?.translate('no_country') ?? 'No country found'),
    );
  }

  @override
  void initState() {
    filteredElements = widget.elements;
    super.initState();
  }

  void _filterElements(String s) {
    s = s.toUpperCase();
    setState(() {
      // First get items that start with the query
      var startsWithMatches = widget.elements.where((e) => e.code!.startsWith(s) || e.dialCode!.startsWith(s) || e.toCountryStringOnly().toUpperCase().startsWith(s)).toSet();

      // Then get items that contain the query but don't start with it
      var containsMatches = widget.elements.where((e) => (!startsWithMatches.contains(e)) && (e.code!.contains(s) || e.dialCode!.contains(s) || e.toCountryStringOnly().toUpperCase().contains(s)));

      // Combine both lists while preserving order
      filteredElements = [
        ...startsWithMatches,
        ...containsMatches
      ];
    });
  }

  void _selectItem(CountryCode e) {
    Navigator.pop(context, e);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
