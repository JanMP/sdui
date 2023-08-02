/* eslint-disable import/extensions */
import { convertTokenBytePairEncodingFromTuples } from '../convertTokenBytePairEncodingFromTuples'
import encoder from '../encodings/cl100k_base.js'
import { GptEncoding } from '../GptEncoding'

export * from '../specialTokens'

const api = GptEncoding.getEncodingApi('cl100k_base', () =>
  convertTokenBytePairEncodingFromTuples(encoder),
)
const {
  decode,
  decodeAsyncGenerator,
  decodeGenerator,
  encode,
  encodeGenerator,
  isWithinTokenLimit,
  encodeChat,
  encodeChatGenerator,
} = api
export {
  decode,
  decodeAsyncGenerator,
  decodeGenerator,
  encode,
  encodeChat,
  encodeChatGenerator,
  encodeGenerator,
  isWithinTokenLimit,
}
// eslint-disable-next-line import/no-default-export
export default api
