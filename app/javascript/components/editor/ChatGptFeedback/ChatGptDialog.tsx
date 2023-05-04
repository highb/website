import React from 'react'
import { Modal } from '@/components/modals'
import { Submission } from '../types'
import { SingleSelect } from '@/components/common'

export type GptModelInfo = {
  version: GPTModel
  usage: number
}
export type GptUsage = {
  chatgpt: {
    '3.5': number
    '4.0': number
  }
}
type ChatGptDialogModalProps = {
  open: boolean
  onClose: () => void
  onGo: () => void
  submission: Submission
  value: GptModelInfo
  setValue: (v: GptModelInfo) => void
  chatgptUsage: GptUsage
}

export type GPTModel = '3.5' | '4.0'

const OptionComponent = ({
  option: model,
}: {
  option: GptModelInfo
}): JSX.Element | null => {
  switch (model.version) {
    case '3.5':
      return (
        <React.Fragment>
          <div className="text-p-base flex items-center w-100">
            ChatGPT 3.5{' '}
            <span className="text-textColor6 font-semibold ml-auto text-14 flex items-center">
              {model.usage}/100
            </span>
          </div>
        </React.Fragment>
      )
    case '4.0':
      return (
        <React.Fragment>
          <div className="text-p-base flex items-center w-100">
            ChatGPT 4{' '}
            <span className="text-textColor6 font-semibold ml-auto text-14 flex items-center">
              {model.usage}/10
            </span>
          </div>
        </React.Fragment>
      )
    default:
      return null
  }
}

const SelectedComponent = ({
  option: model,
}: {
  option: GptModelInfo
}): JSX.Element | null => {
  switch (model.version) {
    case '3.5':
      return (
        <React.Fragment>
          <div className="text-p-base flex items-center w-100">GPT-3.5 </div>
        </React.Fragment>
      )
    case '4.0':
      return (
        <React.Fragment>
          <div className="text-p-base flex items-center w-100">GPT-4 </div>
        </React.Fragment>
      )
    default:
      return null
  }
}

export const ChatGptDialog = ({
  open,
  onClose,
  onGo,
  value,
  setValue,
  chatgptUsage,
}: ChatGptDialogModalProps): JSX.Element => {
  return (
    <Modal
      open={open}
      closeButton={false}
      onClose={onClose}
      shouldCloseOnEsc={false}
      shouldCloseOnOverlayClick
      ReactModalClassName={`max-w-[40%]`}
    >
      <div className="text-h5 mb-16">Are you sure you want to ask ChatGPT?</div>

      <div className="text-textColor6 mt-32">Select a model:</div>
      <SingleSelect<GptModelInfo>
        componentClassName="mb-32 mt-8"
        options={gptUsageToArray(chatgptUsage)}
        OptionComponent={OptionComponent}
        SelectedComponent={SelectedComponent}
        value={value}
        setValue={setValue}
      />
      <div className="flex gap-8">
        <button className="btn-s btn-primary" onClick={onGo}>
          Go
        </button>
        <button className="btn-s btn-default" onClick={onClose}>
          Cancel
        </button>
      </div>
    </Modal>
  )
}

function gptUsageToArray(gptUsage: GptUsage): GptModelInfo[] {
  return Object.entries(gptUsage.chatgpt).map(([version, usage]) => ({
    version: version as GPTModel,
    usage,
  }))
}
