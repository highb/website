import { useEffect, useState } from 'react'
import { MutateFunction, useMutation } from 'react-query'
import { AIHelpRecordsChannel } from '@/channels/aiHelpRecordsChannel'
import { sendRequest } from '@/utils'
import { camelizeKeysAs } from '@/packs/application'
import { Submission } from '../types'

export type HelpRecord = {
  source: string
  adviceHtml: string
}

export type AIHelpRecordsChannelResponse = {
  help_record: HelpRecord
}

export type FetchingStatus = 'unfetched' | 'fetching' | 'received'

export type useChatGptFeedbackProps = {
  helpRecord: HelpRecord | undefined | null
  unfetched: boolean
  mutation: MutateFunction<void, unknown, undefined, unknown>
  setStatus: React.Dispatch<React.SetStateAction<FetchingStatus>>
  status: FetchingStatus
  submissionUuid: string | undefined
  setSubmissionUuid: React.Dispatch<React.SetStateAction<string | undefined>>
}

export function useChatGptFeedback({
  submission,
  defaultRecord,
}: {
  submission: Submission | null
  defaultRecord: HelpRecord
}): useChatGptFeedbackProps {
  const [helpRecord, setHelpRecord] = useState<HelpRecord | undefined>(
    defaultRecord
  )
  const [status, setStatus] = useState<FetchingStatus>(
    defaultRecord ? 'received' : 'unfetched'
  )
  const [submissionUuid, setSubmissionUuid] = useState<string | undefined>()

  const [mutation] = useMutation<void>(
    async () => {
      if (!submission) return
      const { fetch } = sendRequest({
        endpoint: submission?.links.aiHelp,
        method: 'POST',
        body: null,
      })

      // TODO catch errors
      return fetch
        .then(() => setStatus('fetching'))
        .catch((e) => console.log(e))
    },
    { onError: (err) => console.log(err) }
  )

  useEffect(() => {
    if (!submission) return
    const solutionChannel = new AIHelpRecordsChannel(
      submission?.uuid,
      (response: AIHelpRecordsChannelResponse) => {
        setHelpRecord(camelizeKeysAs<HelpRecord>(response.help_record))
        setStatus('received')
      }
    )

    return () => {
      solutionChannel.disconnect()
    }
  }, [mutation, submission])

  return {
    helpRecord,
    mutation,
    unfetched: helpRecord === undefined,
    status,
    setStatus,
    submissionUuid,
    setSubmissionUuid,
  }
}