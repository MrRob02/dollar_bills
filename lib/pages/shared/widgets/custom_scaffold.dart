import 'package:flutter/material.dart';
import 'package:dollar_bills/pages/shared/theme/hex_color.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget? body;
  final bool fullScreenLoading;
  final bool? isLoading;
  final bool hasData;
  final String? emptyMessage;
  final RefreshCallback? onRefresh;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  const CustomScaffold({
    super.key,
    required this.title,
    required this.body,
    this.fullScreenLoading = false,
    this.isLoading,
    this.hasData = true,
    this.emptyMessage,
    this.onRefresh,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  const CustomScaffold.withData({
    super.key,
    required this.title,
    required this.hasData,
    required String this.emptyMessage,
    required Widget this.body,
    this.fullScreenLoading = false,
    this.isLoading,
    this.onRefresh,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (fullScreenLoading) {
      content = Center(
        child: CircularProgressIndicator(color: HexColor.mintPrimary),
      );
    } else if (!hasData) {
      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: HexColor.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyMessage ?? 'No hay datos disponibles',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: HexColor.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      content = body ?? const SizedBox.shrink();
    }

    if (onRefresh != null) {
      content = RefreshIndicator(
        color: HexColor.mintPrimary,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? HexColor.backgroundLight,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: HexColor.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: leading ??
            (showBackButton && Navigator.of(context).canPop()
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: HexColor.textPrimary, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                : null),
        actions: actions,
        bottom: (isLoading ?? false)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  color: HexColor.mintPrimary,
                  backgroundColor: HexColor.mintLight,
                ),
              )
            : null,
      ),
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
