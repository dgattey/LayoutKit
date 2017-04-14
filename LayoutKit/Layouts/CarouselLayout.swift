// Copyright 2016 LinkedIn Corp.
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import CoreGraphics

/**
 Provides a custom collection view layout that allows for a collection view flow layout and sub layouts
 to be passed in.
 - warning: must be strongly retained, otherwise the backing data provider will be nil on cell reuse.
 */
class CarouselLayout: BaseLayout<LayoutAdapterCollectionView> {

    fileprivate let sections: [Section<[LayoutArrangement]>]
    private let collectionViewLayout: CollectionViewLayout

    init(collectionViewLayout: CollectionViewLayout,
         arrangements: [LayoutArrangement] = [],
         alignment: Alignment = .fill,
         flexibility: Flexibility = .flexible,
         viewReuseId: String? = nil,
         config: ((LayoutAdapterCollectionView) -> Void)? = nil) {
        self.sections = [Section(items: arrangements)]
        self.collectionViewLayout = collectionViewLayout
        super.init(alignment: alignment, flexibility: flexibility, viewReuseId: viewReuseId, config: config)
    }

    /**
     Creates a collection view and sets it up with the adapter as the data source and delegate
     (through the `LayoutAdapterCollectionView`).
     */
    override func makeView() -> View {
        let collectionView = LayoutAdapterCollectionView(
            frame: .zero,
            collectionViewLayout: self.collectionViewLayout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delaysContentTouches = false
        return collectionView
    }

    /**
     Reloads the layout provider so it can show the sublayouts
     */
    override func configure(view: LayoutAdapterCollectionView) {
        super.configure(view: view)

        // Actually reload the data so the layout adapter can do its work, using the given card width
        // to constrain the layouts.
        view.layoutAdapter.reload(arrangement: self.sections)
    }
    
}

// MARK: - configurable layout

extension CarouselLayout: ConfigurableLayout {

    /**
     Gets the max height of all sublayouts, then returns its layout measurement. Note: no sublayouts
     given that those are passed through into the layout adapter to lay out.
     */
    func measurement(within maxSize: CGSize) -> LayoutMeasurement {
        // Measure all subarrangements to get the max height
        let sublayoutFrames = self.sections.first?.items.flatMap { $0.frame } ?? []
        let sublayoutMaxHeight: CGFloat = sublayoutFrames.reduce(0.0, { (minHeight, frame) in
            let height = frame.height
            return minHeight >= height ? minHeight : height
        })

        // Make sure we're still within the maxSize
        let contentSize = CGSize(width: maxSize.width, height: sublayoutMaxHeight).decreasedToSize(maxSize)

        // Return the given max width and the max height from the sublayouts
        return LayoutMeasurement(layout: self, size: contentSize, maxSize: maxSize, sublayouts: [])
    }

    /**
     Uses this layout's alignment without any sublayouts.
     */
    func arrangement(within rect: CGRect, measurement: LayoutMeasurement) -> LayoutArrangement {
        let frame = alignment.position(size: measurement.size, in: rect)
        return LayoutArrangement(layout: self, frame: frame, sublayouts: [])
    }

}
