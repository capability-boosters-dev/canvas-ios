/* @flow */

import { refs, entities } from '../reducer'
import { default as ListActions } from '../list/actions'
import { default as DetailsActions } from '../details/actions'
import { default as EditActions } from '../edit/actions'

const { refreshQuizzes } = ListActions
const { refreshQuiz } = DetailsActions
const { updateQuiz } = EditActions

const template = {
  ...require('../../../api/canvas-api/__templates__/quiz'),
  ...require('../../../api/canvas-api/__templates__/error'),
}

describe('refs', () => {
  describe('refreshQuizzes', () => {
    const data = [
      template.quiz({ id: '1' }),
      template.quiz({ id: '2' }),
    ]

    const pending = {
      type: refreshQuizzes.toString(),
      pending: true,
    }

    it('handles pending', () => {
      expect(
        refs(undefined, pending)
      ).toEqual({
        refs: [],
        pending: 1,
      })
    })

    it('handles resolved', () => {
      const initialState = refs(undefined, pending)
      const resolved = {
        type: refreshQuizzes.toString(),
        payload: { result: { data } },
      }
      expect(
        refs(initialState, resolved)
      ).toEqual({
        pending: 0,
        refs: ['1', '2'],
      })
    })

    it('handles rejected', () => {
      const initialState = refs(undefined, pending)
      const rejected = {
        type: refreshQuizzes.toString(),
        error: true,
        payload: { error: template.error('User not authorized') },
      }
      expect(
        refs(initialState, rejected)
      ).toEqual({
        refs: [],
        pending: 0,
        error: `There was a problem loading the quizzes.

User not authorized`,
      })
    })
  })
})

describe('entities', () => {
  describe('refreshQuizzes', () => {
    it('handles resolved', () => {
      const one = template.quiz({ id: '1' })
      const two = template.quiz({ id: '2' })
      const resolved = {
        type: refreshQuizzes.toString(),
        payload: { result: { data: [one, two] } },
      }
      expect(
        entities({}, resolved)
      ).toEqual({
        '1': {
          data: one,
          pending: 0,
          error: null,
        },
        '2': {
          data: two,
          pending: 0,
          error: null,
        },
      })
    })
  })

  describe('refreshQuiz', () => {
    it('handles resolved', () => {
      const quiz = template.quiz({ id: '1' })
      const resolved = {
        type: refreshQuiz.toString(),
        payload: {
          result: [{ data: quiz }],
          courseID: '1',
          quizID: quiz.id,
        },
      }
      expect(
        entities({}, resolved)
      ).toEqual({
        '1': {
          data: quiz,
          pending: 0,
          error: null,
        },
      })
    })
  })

  describe('updateQuiz', () => {
    it('handles pending', () => {
      const quiz = template.quiz({ id: '1' })
      const pending = {
        type: updateQuiz.toString(),
        pending: true,
        payload: {
          originalQuiz: quiz,
          updatedQuiz: quiz,
        },
      }

      expect(
        entities({}, pending)
      ).toEqual({
        '1': {
          pending: 1,
        },
      })
    })

    it('handles rejected', () => {
      const original = template.quiz({ id: '1' })
      const updated = {
        ...original,
        description: 'changed description',
      }
      const rejected = {
        type: updateQuiz.toString(),
        error: true,
        payload: {
          originalQuiz: original,
          updatedQuiz: updated,
          error: template.error('User not authorized'),
        },
      }
      const pendingState = {
        '1': {
          pending: 1,
          data: original,
          error: null,
        },
      }
      expect(
        entities(pendingState, rejected)
      ).toEqual({
        '1': {
          pending: 0,
          data: original,
          error: 'User not authorized',
        },
      })
    })

    it('handles resolved', () => {
      const original = template.quiz({ id: '1' })
      const updated = {
        ...original,
        description: 'changed description',
      }
      const pendingState = {
        '1': {
          pending: 1,
          data: original,
          error: null,
        },
      }
      const resolved = {
        type: updateQuiz.toString(),
        payload: {
          originalQuiz: original,
          updatedQuiz: updated,
        },
      }
      expect(
        entities(pendingState, resolved)
      ).toEqual({
        '1': {
          pending: 0,
          data: updated,
          error: null,
        },
      })
    })
  })
})
