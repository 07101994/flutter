// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void verifyPaintPosition(GlobalKey key, Offset ideal, bool visible) {
  final RenderSliver target = key.currentContext.findRenderObject();
  expect(target.parent, const isInstanceOf<RenderViewport>());
  final SliverPhysicalParentData parentData = target.parentData;
  final Offset actual = parentData.paintOffset;
  expect(actual, ideal);
  final SliverGeometry geometry = target.geometry;
  expect(geometry.visible, visible);
}

void verifyActualBoxPosition(WidgetTester tester, Finder finder, int index, Rect ideal) {
  final RenderBox box = tester.renderObjectList<RenderBox>(finder).elementAt(index);
  final Rect rect = new Rect.fromPoints(box.localToGlobal(Point.origin), box.localToGlobal(box.size.bottomRight(Point.origin)));
  expect(rect, equals(ideal));
}

void main() {
  testWidgets('Sliver appbars - floating - scroll offset doesn\'t change', (WidgetTester tester) async {
    const double bigHeight = 1000.0;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(height: bigHeight),
          new SliverPersistentHeader(delegate: new TestDelegate(), floating: true),
          new BigSliver(height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final double max = bigHeight * 2.0 + new TestDelegate().maxExtent - 600.0; // 600 is the height of the test viewport
    assert(max < 10000.0);
    expect(max, 1600.0);
    expect(position.pixels, 0.0);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
    position.animateTo(10000.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(position.pixels, max);
    expect(position.minScrollExtent, 0.0);
    expect(position.maxScrollExtent, max);
  });

  testWidgets('Sliver appbars - floating - normal behavior works', (WidgetTester tester) async {
    final TestDelegate delegate = new TestDelegate();
    const double bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: delegate, floating: true),
          new BigSliver(key: key3 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    verifyPaintPosition(key1, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, const Offset(0.0, 600.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 600.0), false);

    position.animateTo(bigHeight - 600.0 + delegate.maxExtent, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0 - delegate.maxExtent), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 600.0 - delegate.maxExtent, 800.0, delegate.maxExtent));
    verifyPaintPosition(key3, const Offset(0.0, 600.0), false);

    assert(delegate.maxExtent * 2.0 < 600.0); // make sure this fits on the test screen...
    position.animateTo(bigHeight - 600.0 + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, new Offset(0.0, 600.0 - delegate.maxExtent * 2.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 600.0 - delegate.maxExtent * 2.0, 800.0, delegate.maxExtent));
    verifyPaintPosition(key3, new Offset(0.0, 600.0 - delegate.maxExtent), true);

    position.animateTo(bigHeight, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent), true);

    position.animateTo(bigHeight + delegate.maxExtent * 0.1, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent * 0.9));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent * 0.9), true);

    position.animateTo(bigHeight + delegate.maxExtent * 0.5, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, 0.0, 800.0, delegate.maxExtent * 0.5));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent * 0.5), true);

    position.animateTo(bigHeight + delegate.maxExtent * 0.9, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, -delegate.maxExtent * 0.4, 800.0, delegate.maxExtent * 0.5));
    verifyPaintPosition(key3, new Offset(0.0, delegate.maxExtent * 0.1), true);

    position.animateTo(bigHeight + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 0.0), true);
  });

  testWidgets('Sliver appbars - floating - no floating behavior when animating', (WidgetTester tester) async {
    final TestDelegate delegate = new TestDelegate();
    const double bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: delegate, floating: true),
          new BigSliver(key: key3 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    verifyPaintPosition(key1, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, const Offset(0.0, 600.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 600.0), false);

    position.animateTo(bigHeight + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 0.0), true);

    position.animateTo(bigHeight + delegate.maxExtent * 1.9, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 0.0), true);
  });

  testWidgets('Sliver appbars - floating - floating behavior when dragging down', (WidgetTester tester) async {
    final TestDelegate delegate = new TestDelegate();
    const double bigHeight = 1000.0;
    GlobalKey key1, key2, key3;
    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new BigSliver(key: key1 = new GlobalKey(), height: bigHeight),
          new SliverPersistentHeader(key: key2 = new GlobalKey(), delegate: delegate, floating: true),
          new BigSliver(key: key3 = new GlobalKey(), height: bigHeight),
        ],
      ),
    );
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;

    verifyPaintPosition(key1, const Offset(0.0, 0.0), true);
    verifyPaintPosition(key2, const Offset(0.0, 600.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 600.0), false);

    position.animateTo(bigHeight + delegate.maxExtent * 2.0, curve: Curves.linear, duration: const Duration(minutes: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key3, const Offset(0.0, 0.0), true);

    position.animateTo(bigHeight + delegate.maxExtent * 1.9, curve: Curves.linear, duration: const Duration(minutes: 1));
    position.updateUserScrollDirection(ScrollDirection.forward); // ignore: INVALID_USE_OF_PROTECTED_MEMBER, since this is using a protected method for testing purposes
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    verifyPaintPosition(key1, const Offset(0.0, 0.0), false);
    verifyPaintPosition(key2, const Offset(0.0, 0.0), true);
    verifyActualBoxPosition(tester, find.byType(Container), 0, new Rect.fromLTWH(0.0, -delegate.maxExtent * 0.4, 800.0, delegate.maxExtent * 0.5));
    verifyPaintPosition(key3, const Offset(0.0, 0.0), true);
  });

  testWidgets('Sliver appbars - floating - overscroll gap is below header', (WidgetTester tester) async {
    await tester.pumpWidget(
      new CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          new SliverPersistentHeader(delegate: new TestDelegate(), floating: true),
          new SliverList(
            delegate: new SliverChildListDelegate(<Widget>[
              const SizedBox(
                height: 300.0,
                child: const Text('X'),
              ),
            ]),
          ),
        ],
      ),
    );

    expect(tester.getTopLeft(find.byType(Container)), Point.origin);
    expect(tester.getTopLeft(find.text('X')), const Point(0.0, 200.0));

    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(-50.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(Container)), Point.origin);
    expect(tester.getTopLeft(find.text('X')), const Point(0.0, 250.0));
  });
}

class TestDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get maxExtent => 200.0;

  @override
  double get minExtent => 100.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(constraints: new BoxConstraints(minHeight: minExtent, maxHeight: maxExtent));
  }

  @override
  bool shouldRebuild(TestDelegate oldDelegate) => false;
}


class RenderBigSliver extends RenderSliver {
  RenderBigSliver(double height) : _height = height;

  double get height => _height;
  double _height;
  set height(double value) {
    if (value == _height)
      return;
    _height = value;
    markNeedsLayout();
  }

  double get paintExtent => (height - constraints.scrollOffset).clamp(0.0, constraints.remainingPaintExtent);

  @override
  void performLayout() {
    geometry = new SliverGeometry(
      scrollExtent: height,
      paintExtent: paintExtent,
      maxPaintExtent: height,
    );
  }
}

class BigSliver extends LeafRenderObjectWidget {
  BigSliver({ Key key, this.height }) : super(key: key);

  final double height;

  @override
  RenderBigSliver createRenderObject(BuildContext context) {
    return new RenderBigSliver(height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBigSliver renderObject) {
    renderObject.height = height;
  }
}
