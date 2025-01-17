import QtQuick 2.6
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.2

Page {
    id: page

    allowedOrientations: limitScreenOrientation

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        id: container
        anchors.fill: parent
        //height: contentItem.childrenRect.height
        width: page.width

        VerticalScrollDecorator { flickable: container }

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: "About"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: "Help"
                onClicked: pageStack.push(Qt.resolvedUrl("HelpPage.qml"))
            }
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }
        PushUpMenu {
            MenuItem {
                text: qsTr("Copy result")
                onClicked: Clipboard.text = result_TextArea.text
            }
            MenuItem {
                text: qsTr("Copy formula")
                onClicked: Clipboard.text = expression_TextField.text
            }
        }

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id : limit_Column
            width: page.width
            spacing: Theme.paddingSmall

            function calculateResultLimit() {
                result_TextArea.text = 'Calculating limit...'
                py.call('limit.calculate_Limit', [expression_TextField.text,variable_TextField.text,point_TextField.text,direction_ComboBox.value,orientation!==Orientation.Landscape,showLimit,showTime,numerApprox,numDigText,simplifyResult_index,outputTypeResult_index], function(result) {
                    result_TextArea.text = result;
                })
            }
            function copyResult() {
                result_TextArea.selectAll()
                result_TextArea.copy()
                result_TextArea.deselect()
            }

            PageHeader {
                title: qsTr("Limit")
            }
            TextField {
                id: expression_TextField
                inputMethodHints: Qt.ImhNoAutoUppercase
                placeholderText: "sin(x)/x"
                label: qsTr("Limit expression")
                width: parent.width
                text : "sin(x)/x"
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: variable_TextField.focus = true
            }
            Row {
                width: parent.width
                TextField {
                    id: variable_TextField
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    width: parent.width*0.5
                    placeholderText: "x"
                    label: qsTr("Variable")
                    text : "x"
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: point_TextField.focus = true
                }
                TextField {
                    id: point_TextField
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    width: parent.width*0.5
                    placeholderText: "0"
                    label: qsTr("Point")
                    text : "0"
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: limit_Column.calculateResultLimit()
                }
            }
            Row {
                width: parent.width
                ComboBox {
                    id: direction_ComboBox
                    width: page.width*0.55
                    label: qsTr("Direction ")
                    currentIndex: 0
                    menu: ContextMenu {
                        MenuItem { text: "Bilateral" }
                        MenuItem { text: "Left" }
                        MenuItem { text: "Right" }
                    }
                }
                Button {
                    id: calculate_Button
                    width: parent.width*0.35
                    text: qsTr("Calculate")
                    focus: true
                    onClicked: limit_Column.calculateResultLimit()
                }
            }
            Separator {
                id : limit_Separator
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width*0.9
                color: Theme.primaryColor
            }
            FontLoader { id: dejavusansmono; source: "file:DejaVuSansMono.ttf" }

            Label {
               id:timer
                anchors {
                    left: limit_Separator.left
                    topMargin: 2 * Theme.paddingLarge
                    bottomMargin: 2 * Theme.paddingLarge
                }
               width: parent.width  - Theme.paddingLarge
               text: timerInfo
               color: Theme.highlightColor
            }

            TextArea {
                id: result_TextArea

                height: implicitHeight + Theme.paddingLarge //Math.max(page.width, 1080, implicitHeight)
                width: parent.width
                readOnly: true
                font.family: dejavusansmono.name
                color: 'lightblue'
                font.pixelSize: Theme.fontSizeSmallBase
                text : 'Loading Python and SymPy ...'
                Component.onCompleted: {
                    //_editor.textFormat = Text.RichText;
                }

                /* for the cover we hold the value */
                onTextChanged: {
                    console.log(implicitHeight)
                    resultText = scaleText(text)
                }
                /* for the cover we scale font px values */
                /* on the cover we can use html */
                function scaleText(text) {
                    const txt = '<FONT COLOR="lightblue" SIZE="16px"><pre>'
                    txt = txt + text + '<pre></FONT>'
                    return txt
                }
            }

            Python {
                id: py

                Component.onCompleted: {
                    // Add the Python library directory to the import path
                    var pythonpath = Qt.resolvedUrl('.').substr('file://'.length);
                    addImportPath(pythonpath);
                    console.log(pythonpath);

                    setHandler('timerPush', timerPushHandler);

                    // Asynchronous module importing
                    importModule('limit', function() {
                        //console.log('Python version: ' + evaluate('limit.versionPython'));
                        //console.log('SymPy version ' + evaluate('limit.versionSymPy') + evaluate('(" loaded in %f seconds.\n" % limit.loadingtimeSymPy)'));
                        result_TextArea.text='Python version ' + evaluate('limit.versionPython') + '.\n'
                        result_TextArea.text+='SymPy version ' + evaluate('limit.versionSymPy') + '\n'
                        timerInfo = evaluate('("loaded in %f seconds." % limit.loadingtimeSymPy)')
                    });
                }

                // shared via timerInfo with cover
                function timerPushHandler(pTimer) {
                    timerInfo = "Calculated in: " + pTimer
                }

                onError: {
                    // when an exception is raised, this error handler will be called
                    console.log('python error: ' + traceback);
                }

                onReceived: {
                    // asychronous messages from Python arrive here
                    // in Python, this can be accomplished via pyotherside.send()
                    console.log('got message from python: ' + data);
                }
            }
        }
    }
}
