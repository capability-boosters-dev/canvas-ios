  // @flow

import React, { Component } from 'react'
import {
  View,
  StyleSheet,
  Image,
  TextInput,
  TouchableOpacity,
} from 'react-native'
import i18n from 'format-message'
import Images from '../../../images'
import colors from '../../../common/colors'
import KeyboardSpacer from 'react-native-keyboard-spacer'
import DrawerState from '../utils/drawer-state'

export type Comment
  = { type: 'text', message: string }

type CommentInputProps = {
  makeComment(comment: Comment): void,
  drawerState: DrawerState,
  allowMediaComments: boolean,
  initialValue: ?string,
  disabled: boolean,
  autoFocus?: boolean,
  onBlur?: () => void,
}

type State = {
  textComment: string,
}

export default class CommentInput extends Component<any, CommentInputProps, any> {
  state: State
  _textInput: TextInput

  constructor (props: CommentInputProps) {
    super(props)
    this.state = { textComment: props.initialValue || '' }
  }

  addMedia = () => {
    console.log('Add some media!')
  }

  makeComment = () => {
    let text = this.state.textComment
    if (!text || text.length === 0) {
      return
    }
    this.setState({ textComment: '' })
    this._textInput.blur()

    this.props.makeComment({
      type: 'text',
      message: text,
    })
  }

  keyboardChanged = (visible: boolean) => {
    if (visible) {
      this.props.drawerState.snapTo(2, true)
    }
  }

  textChanged = (text: string) => {
    this.setState({ textComment: text })
  }

  onBlur = () => {
    this.props.onBlur && this.props.onBlur()
  }

  captureTextInput = (textInput: TextInput) => {
    this._textInput = textInput
  }

  render () {
    const placeholder = i18n('Comment')

    const addMedia = i18n('Add Media')

    const send = i18n('Send')

    const disableSend = !this.state.textComment || this.state.textComment.length === 0 || this.props.disabled

    return (
      <View>
        <View style={styles.toolbar}>
          {this.props.allowMediaComments &&
            <TouchableOpacity
              style={styles.mediaButton}
              testID='comment-input.add-media'
              onPress={this.addMedia}
              accessible
              accessibilityLabel={addMedia}
              accessibilityTraits={['button']}
            >
              <Image
                resizeMode="center"
                source={Images.add}
                style={styles.plus}
              />
            </TouchableOpacity>
          }
          <View style={styles.inputContainer}>
            <TextInput
              autoFocus={
                (typeof (jest) === 'undefined') &&
                this.props.autoFocus != null &&
                this.props.autoFocus
              }
              multiline
              testID='comment-input.comment'
              placeholder={placeholder}
              placeholderTextColor={colors.lightText}
              style={styles.input}
              maxHeight={76}
              onChangeText={this.textChanged}
              ref={this.captureTextInput}
              value={this.state.textComment}
              onBlur={this.onBlur}
            />
            {
              this.state.textComment != null &&
              this.state.textComment.length > 0 &&
              <TouchableOpacity
                style={styles.sendButton}
                testID='comment-input.send'
                onPress={!disableSend ? this.makeComment : null}
                accessibilityLabel={send}
                accessibilityTraits={['button']}
                activeOpacity={disableSend ? 1 : 0.2}
              >
                <Image
                  style={styles.sendButtonArrow}
                  source={Images.upArrow}
                />
              </TouchableOpacity>
            }
          </View>
        </View>
        <KeyboardSpacer onToggle={this.keyboardChanged} />
    </View>
    )
  }
}

CommentInput.defaultProps = {
  allowMediaComments: true,
  disabled: false,
}

const styles = StyleSheet.create({
  mediaButton: {
    alignSelf: 'center',
  },
  plus: {
    tintColor: colors.secondaryButton,
  },
  toolbar: {
    overflow: 'hidden',
    backgroundColor: '#F5F5F5',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: colors.seperatorColor,
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    paddingVertical: 8,
    paddingHorizontal: global.style.defaultPadding,
  },
  inputContainer: {
    flex: 1,
    borderRadius: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: colors.seperatorColor,
    overflow: 'hidden',
    backgroundColor: 'white',
    marginLeft: 4,
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  input: {
    fontSize: 16,
    lineHeight: 19,
    marginLeft: 10,
    marginRight: 24,
    marginTop: 2,
    marginBottom: 6,
    flex: 1,
  },
  sendButton: {
    backgroundColor: colors.primaryButton,
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    flex: 0,
    marginTop: 4,
    marginRight: 4,
  },
  sendButtonArrow: {
    tintColor: 'white',
    marginBottom: 1,
  },
})
