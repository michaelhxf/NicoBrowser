/*
 * Copyright (c) 2011-2014 BlackBerry Limited.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import bb.cascades 1.2
import bb.system 1.2
import bb.data 1.0

TabbedPane {
    id: tabb
    showTabsOnActionBar: false

    attachedObjects: [

        Sheet {
            id: bmsheet
            property WebView web
            property bool isEditMode
            Page {

                titleBar: TitleBar {
                    id: bmTitle
                    title: "Bookmark (m=Close e=Edit)"
                    appearance: TitleBarAppearance.Plain
                }

                ListView {
                    id: bmlist
                    dataModel: bookmarkModel

                    listItemComponents: ListItemComponent {
                        type: "item"
                        Container {
                            preferredHeight: 40
                            Label {
                                preferredHeight: 20
                                text: ListItemData.title
                                verticalAlignment: VerticalAlignment.Top
                                layoutProperties: StackLayoutProperties {

                                }
                                horizontalAlignment: HorizontalAlignment.Center
                                textFormat: TextFormat.Plain
                            }
                            Label {
                                preferredHeight: 20
                                text: ListItemData.address
                                verticalAlignment: VerticalAlignment.Top
                                layoutProperties: StackLayoutProperties {

                                }
                                horizontalAlignment: HorizontalAlignment.Center
                                textStyle.fontSize: FontSize.XSmall
                                textStyle.color: Color.Gray
                                textFormat: TextFormat.Plain
                            }

                        }
                    }
                    layout: GridListLayout {
                        columnCount: 2

                    }

                    onTriggered: {
                        var chosen = dataModel.data(indexPath)

                        if (! bmsheet.isEditMode) {
                            bmsheet.web.evaluateJavaScript("window.location.href=\"" + chosen.address + "\"")
                            bmsheet.close()
                        } else {
                            bookmarkSource.query = "DELETE FROM bookmark WHERE id=" + chosen.id
                            bookmarkSource.load()
                        }
                    }
                }

                shortcuts: [
                    Shortcut {
                        key: "m"
                        onTriggered: {
                            bmsheet.isEditMode = false
                            bmsheet.close()
                        }
                    },
                    Shortcut {
                        key: "e"
                        onTriggered: {
                            if (bmsheet.isEditMode) {
                                bmsheet.isEditMode = false
                                bmTitle.title = "Bookmark (m=Close e=Edit)"
                            } else {
                                bmsheet.isEditMode = true
                                bmTitle.title = "Bookmark (m=Close e=Edit)[EDIT MODE]"
                            }

                        }
                    }
                ]
            }

        },
        SystemToast {
            id: toast
        },
        DataSource {
            id: bookmarkSource
            source: "file://" + nicobrowser.getDatabasePath()
            type: DataSourceType.Sql
            remote: false

            onDataLoaded: {
                //select
                if (bookmarkSource.query.indexOf("SELECT") == 0) {
                    bookmarkModel.clear()
                    bookmarkModel.insertList(data)
                }

                //insert
                if (bookmarkSource.query.indexOf("VALUES") > 0) {
                    toast.body = "bookmark added"
                    toast.show()
                }

                //delete
                if (bookmarkSource.query.indexOf("WHERE") > 0) {
                    toast.body = "bookmark deleted"
                    toast.show()
                    bookmarkSource.query = "SELECT id,title,address FROM bookmark"
                    bookmarkSource.load()
                }

            }
        },
        GroupDataModel {
            id: bookmarkModel
            sortingKeys: [ "id" ]
            sortedAscending: false
            grouping: ItemGrouping.None
        },

        ComponentDefinition {
            id: webTab
            Tab {
                id: tabtemp
                title: "New Tab"
                imageSource: "asset:///images/pin_blue.png"

                Page {
                    id: webPage
                    property TabbedPane tabPanel
                    property Tab currentTab
                    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
                    actionBarVisibility: ChromeVisibility.Visible

                    actions: [
                        ActionItem {
                            title: "open"
                            ActionBar.placement: ActionBarPlacement.OnBar

                            onTriggered: {
                                if (urlTextField.visible)
                                    urlTextField.visible = false;
                                else
                                    urlTextField.visible = true
                                urlTextField.requestFocus()
                            }

                            shortcuts: [
                                Shortcut {
                                    key: "o"

                                }
                            ]
                            imageSource: "asset:///images/document-edit_blue.png"
                        },
                        ActionItem {
                            title: "Back"
                            ActionBar.placement: ActionBarPlacement.OnBar
                            onTriggered: {
                                webview.goBack()
                            }
                            shortcuts: [
                                Shortcut {
                                    key: "q"

                                }
                            ]
                            imageSource: "asset:///images/arrow-left_blue.png"
                        },

                        ActionItem {
                            title: "Stop"
                            imageSource: "asset:///images/button-cross_basic_blue.png"
                            onTriggered: {
                                webview.stop()
                            }
                            shortcuts: Shortcut {
                                key: "s"
                            }
                            ActionBar.placement: ActionBarPlacement.OnBar
                        },

                        ActionItem {
                            title: "Setting"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            imageSource: "asset:///images/gear_yellow.png"
                        },

                        ActionItem {
                            title: "Reload"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            onTriggered: {
                                webview.reload()
                            }
                            shortcuts: [
                                Shortcut {
                                    key: "r"

                                }
                            ]
                            imageSource: "asset:///images/button-synchronize_basic_blue.png"
                        },
                        ActionItem {
                            title: "Forward"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            onTriggered: {
                                webview.goForward()
                            }
                            shortcuts: [
                                Shortcut {
                                    key: "f"

                                }
                            ]
                        },
                        ActionItem {
                            title: "Book Mark"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            imageSource: "asset:///images/star_yellow.png"
                            onTriggered: {
                                bmsheet.open()
                                bookmarkSource.query = "SELECT id,title,address FROM bookmark"
                                bookmarkSource.load()
                                bmsheet.web = webview
                            }
                            shortcuts: Shortcut {
                                key: "m"
                            }
                        },

                        ActionItem {
                            title: "add Book Mark"

                            onTriggered: {
                                if (webview.isLoaded) {
                                    bookmarkSource.query = "INSERT INTO bookmark (title, address) VALUES ('" + webview.title + "' ,'" + webview.url + "')"
                                    bookmarkSource.load()
                                }

                            }

                            shortcuts: Shortcut {
                                key: "v"
                            }
                        },

                        ActionItem {
                            title: "scroll lock"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            onTriggered: {
                                if (scrollview.scrollViewProperties.scrollMode != ScrollMode.Both) {
                                    scrollview.scrollToPoint(0, 0)
                                    scrollview.scrollViewProperties.scrollMode = ScrollMode.Both
                                } else {
                                    scrollview.scrollToPoint(0, 0)
                                    scrollview.scrollViewProperties.scrollMode = ScrollMode.None
                                }
                            }

                            shortcuts: Shortcut {
                                key: "l"
                            }
                        },

                        ActionItem {
                            title: "Hide Bar"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            onTriggered: {
                                if (showBarBtn.visible) {
                                    showBarBtn.visible = false
                                    webPage.actionBarVisibility = ChromeVisibility.Visible
                                } else {
                                    showBarBtn.visible = true
                                    webPage.actionBarVisibility = ChromeVisibility.Hidden
                                }
                            }
                            shortcuts: Shortcut {
                                key: "z"
                            }
                        },
                        ActionItem {
                            title: "show peek"
                            ActionBar.placement: ActionBarPlacement.InOverflow
                            onTriggered: {
                                if (tabb.sidebarState != SidebarState.VisibleFull) {
                                    tabb.sidebarState = SidebarState.VisibleFull
                                } else {
                                    tabb.sidebarState = SidebarState.Hidden
                                }
                            }
                            shortcuts: Shortcut {
                                key: "d"
                            }
                        },
                        ActionItem {
                            title: "close tab"
                            ActionBar.placement: ActionBarPlacement.InOverflow

                            onTriggered: {
                                if (tabb.count() > 2) {
                                    tabb.remove(tabb.activeTab)
                                    tabb.activeTab = tabb.tabs[0]
                                }
                            }

                            shortcuts: Shortcut {
                                key: "p"
                            }
                        }

                    ]

                    Container {
                        layout: DockLayout {

                        }

                        background: Color.White
                        ScrollView {
                            id: scrollview
                            onFocusedChanged: {
                                if (focused) {
                                    showBarBtn.visible = true
                                    webPage.actionBarVisibility = ChromeVisibility.Hidden
                                }
                            }

                            Container {

                                WebView {
                                    id: webview
                                    settings.userAgent: "Mozilla/5.0 (iPod; CPU iPhone OS 5_0_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A405 Safari/7534.48.3"
                                    url: "about:blank"

                                    property int swipX
                                    property int swipY
                                    property int oldX
                                    property int oldY
                                    property bool swipEnable
                                    property bool isToRightDirection
                                    property bool isLoaded

                                    onLoadingChanged: {
                                        if (loadRequest.status == WebLoadStatus.Started) {
                                            progress.visible = true

                                            //hide
                                            webPage.actionBarVisibility = ChromeVisibility.Hidden
                                            webview.requestFocus()
                                            showBarBtn.visible = true
                                        }

                                        if (loadRequest.status == WebLoadStatus.Failed) {
                                            progress.visible = false
                                        }

                                        if (loadRequest.status == WebLoadStatus.Succeeded) {
                                            //webTab = webview.url
                                            progress.visible = false;
                                            isLoaded = true
                                        }

                                        urlTextField.visible = false
                                    }

                                    onTitleChanged: {
                                        tabtemp.title = webview.title
                                    }

                                    onLoadProgressChanged: {
                                        progress.value = loadProgress
                                        
                                        if (loadProgress == 100)
                                            progress.visible = false
                                    }
                                    settings.zoomToFitEnabled: true

                                    onUrlChanged: {
                                        webLocationLA.text = url
                                    }

                                    onNavigationRequested: {
                                        progress.visible = true
                                    }

                                    onTouch: {
                                        if (event.touchType == TouchType.Down && (event.windowX < 60 || event.windowX > 600)) {
                                            swipEnable = true
                                            oldX = event.windowX
                                            oldY = event.windowY
                                            swipX = 0
                                            swipY = 0
                                        }

                                        if (event.touchType == TouchType.Move && swipEnable) {
                                            if (event.windowX > oldX) {
                                                swipX += (event.windowX - oldX);
                                                isToRightDirection = true
                                            } else {
                                                swipX += (oldX - event.windowX)
                                                isToRightDirection = false
                                            }

                                            if (event.windowY > oldY)
                                                swipY += (event.windowY - oldY);
                                            else
                                                swipY += (oldY - event.windowY)
                                        }

                                        if (event.touchType == TouchType.Up) {
                                            if (swipEnable) {
                                                if (swipX / swipY > 10) {
                                                    if (isToRightDirection) {
                                                        webview.goBack()
                                                    } else {
                                                        webview.goForward()
                                                    }
                                                }

                                                //console.log("swipx:" + swipX + "   swipy:" + swipY)
                                            } else {
                                                swipX = 0
                                                swipY = 0
                                            }
                                        }

                                        if (event.touchType == TouchType.Cancel) {
                                            swipEnable = false
                                        }
                                    }
                                }

                            }

                        }

                        ProgressIndicator {
                            visible: false
                            id: progress
                            toValue: 100.0
                            fromValue: 0.0
                            layoutProperties: StackLayoutProperties {

                            }
                            verticalAlignment: VerticalAlignment.Top
                            horizontalAlignment: HorizontalAlignment.Center
                        }

                        Container {
                            visible: true
                            id: showBarBtn
                            preferredWidth: 720
                            preferredHeight: 20

                            layoutProperties: StackLayoutProperties {

                            }
                            verticalAlignment: VerticalAlignment.Bottom
                            horizontalAlignment: HorizontalAlignment.Center

                            Label {
                                id: webLocationLA
                                text: webview.url
                                layoutProperties: StackLayoutProperties {

                                }
                                verticalAlignment: VerticalAlignment.Center
                                textStyle.fontSize: FontSize.XXSmall
                                textStyle.textAlign: TextAlign.Left
                                textStyle.color: Color.White

                                onTouch: {
                                    showBarBtn.visible = false
                                    webPage.actionBarVisibility = ChromeVisibility.Visible
                                }

                            }

                            background: Color.Black
                            layout: DockLayout {

                            }
                            onTouch: {
                                showBarBtn.visible = false
                                webPage.actionBarVisibility = ChromeVisibility.Visible
                            }

                        }

                        Container {
                            verticalAlignment: VerticalAlignment.Bottom
                            horizontalAlignment: HorizontalAlignment.Center
                            background: Color.Black
                            layoutProperties: StackLayoutProperties {

                            }
                            TextField {
                                id: urlTextField
                                visible: false

                                shortcuts: [
                                    Shortcut {
                                        key: "Enter"
                                        onTriggered: {
                                            //may have right url format
                                            if (urlTextField.text.indexOf(".") > 0) {
                                                webview.evaluateJavaScript("window.location.href=\"http://" + urlTextField.text + "\"")

                                            } else {
                                                webview.evaluateJavaScript("window.location.href=\"http://www.google.com/?q=" + urlTextField.text + "\"")
                                            }

                                            webview.requestFocus()
                                        }
                                    }
                                ]

                            }
                        }
                    }
                }
            }
        }
    ]

    function addNewTab() {
        tabb.insert(tabb.count() - 1, webTab.createObject())
        tabb.activeTab = tabb.tabs[tabb.count() - 2]
    }

    onCreationCompleted: {
        nicobrowser.initDatabase(false)
        addNewTab()

    }

    peekEnabled: false
    Tab { //Second tab
        id: addTab
        title: qsTr("Add New Tab") + Retranslate.onLocaleOrLanguageChanged
        onTriggered: {
            addNewTab()
        }
        imageSource: "asset:///images/button-add_basic_blue.png"
    } //End of second tab

}
