/**
 * Plugin to fix this issue in webkit browsers
 * Bug description http://dev.ckeditor.com/ticket/9998

 * It removes spans created by webkit browsers
 * It preserves existing spans created by the user
 * Logs information on the console when removing, merging etc.
 *
 * @author pr0nbaer
 * @version 0.0.2
 */
(function() {
    // register plugin
    CKEDITOR.plugins.add('webkit-span-fix', {
        // initialize plugin
        init: function(editor) {

            ////////////////////////////////////////////////////////////////////////
            // Webkit Span Bugfix //////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////

            // only for Webkit browsers
            if (CKEDITOR.env.webkit) {

                // console.log('>>> Using Webkit Span Bugfix');

                var getParentsToClosestBlockElement = function(node) {
                    var parentsToBlockElement = [];
                    var parents;

                    if (node instanceof CKEDITOR.dom.element || node instanceof CKEDITOR.dom.text) {
                        // get all parent nodes of the node (including the node itself)
                        parents = node.getParents(true);

                        // if parent nodes exist
                        if (parents !== null) {

                            // loop over parent nodes
                            for (var i = 0; i < parents.length; i++) {

                                parentsToBlockElement[i] = parents[i];

                                // if the current parent element has block display, then hold on to the previous parent element and break
                                if (i >= 1 && parents[i] instanceof CKEDITOR.dom.element && parents[i].getComputedStyle('display') == 'block') {
                                    break;
                                }
                            }
                        }
                    }
                    return parentsToBlockElement;
                };

                var getNextNodeSiblingsOfSelection = function() {
                    // the return array
                    var siblings  = [];
                    // get selection
                    var selection = editor.getSelection();
                    var nextNode;
                    var ranges;
                    var nextNodeParents;
                    var element;

                    // if selection exists
                    if (selection !== null) {

                        // get selection ranges
                        ranges = selection.getRanges();

                        // if ranges exist
                        if (ranges.length) {

                            nextNode = ranges[0].getNextNode();

                            // if node exists
                            if (nextNode !== null) {

                                nextNodeParents = getParentsToClosestBlockElement(nextNode);

                                // if element exists
                                if (nextNodeParents[nextNodeParents.length - 2] !== undefined) {

                                    element = nextNodeParents[nextNodeParents.length - 2];

                                    // hold on to the element and all of its siblings
                                    do {

                                        siblings.push(element);
                                        element = element.getNext();

                                    } while (element !== null);

                                }

                            }

                        }

                    }

                    var redoSelection = function() {
                        if (selection !== null && ranges !== null && ranges.length) {
                            selection.selectRanges(ranges);
                        }
                    };

                    return {
                        'siblings': siblings,
                        'redoSelection': redoSelection,
                        'nextNode': nextNode
                    };

                };

                // if editor is in edit-mode
                editor.on('contentDom', function() {

                    // if keydown event was triggered
                    editor.document.on('keydown', function(event) {

                        var nextNodeSiblingsOnKeyDown = getNextNodeSiblingsOfSelection();

                        // bind keyDown event on keyUp once
                        // => will be called after Chrome sets SPAN elements! ;)
                        editor.document.once('keyup', function(event) {

                            var nextNodeSiblingsOnKeyUp = getNextNodeSiblingsOfSelection();

                            var blockElementsMerged = false;

                            if (nextNodeSiblingsOnKeyDown.nextNode !== null && nextNodeSiblingsOnKeyUp.nextNode !== null) {

                                var nextNodeOnKeyDownParents = getParentsToClosestBlockElement(nextNodeSiblingsOnKeyDown.nextNode);
                                var nextNodeOnKeyUpParents = getParentsToClosestBlockElement(nextNodeSiblingsOnKeyUp.nextNode);

                                if (nextNodeOnKeyDownParents[nextNodeOnKeyDownParents.length - 1].getAddress().join('|') != nextNodeOnKeyUpParents[nextNodeOnKeyUpParents.length - 1].getAddress().join('|')) {

                                    blockElementsMerged = true;

                                }

                            }

                            if (blockElementsMerged) {

                                // console.log('>>> Detected merge of block elements');

                                for (var i = 0; i < nextNodeSiblingsOnKeyDown.siblings.length; i++) {

                                    if (nextNodeSiblingsOnKeyUp.siblings[i] === undefined) break;

                                    nodeBeforeKey = nextNodeSiblingsOnKeyDown.siblings[i];
                                    nodeAfterKey = nextNodeSiblingsOnKeyUp.siblings[i];

                                    // convert text node to SPAN element
                                    if (nodeBeforeKey instanceof CKEDITOR.dom.text && nodeAfterKey instanceof CKEDITOR.dom.element && nodeAfterKey.getName() == 'span') {

                                        // console.log('>>> Remove Webkit Span', nodeAfterKey.getOuterHtml());
                                        nodeAfterKey.remove(true);

                                    // modify style attribute of inline element
                                    } else if (nodeBeforeKey instanceof CKEDITOR.dom.element
                                            && nodeAfterKey instanceof CKEDITOR.dom.element
                                            && nodeAfterKey.getComputedStyle('display').match(/^inline/)
                                            && nodeAfterKey instanceof CKEDITOR.dom.element
                                            && nodeAfterKey.getName() == nodeBeforeKey.getName()
                                            && nodeAfterKey.getAttribute('style') != nodeBeforeKey.getAttribute('style')) {

                                        if ( nodeBeforeKey.getAttribute('style') != null ) {

                                            // console.log('>>> Update Webkit Span Style Attribute', nodeAfterKey.getOuterHtml(), 'to', nodeBeforeKey.getAttribute('style'));
                                            nodeAfterKey.setAttribute('style', nodeBeforeKey.getAttribute('style'));

                                        } else {

                                            // console.log('>>> Remove Webkit Span Style Attribute', nodeAfterKey.getOuterHtml());
                                            nodeAfterKey.removeAttribute('style');

                                        }

                                    }
                                    // Bugfix => restore selection
                                    nextNodeSiblingsOnKeyUp.redoSelection();
                                }
                            }
                        });
                    });
                });
            }
        }
    });
})();
