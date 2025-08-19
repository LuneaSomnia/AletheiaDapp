import { http } from 'msw'
import claims from './data/claims.json'

export const handlers = [
  http.get('/api/claims', () => {
    return Response.json(claims)
  }),
  
  http.get('/api/claims/:id', ({ params }) => {
    const claim = claims.find(c => c.id === Number(params.id))
    return claim 
      ? Response.json(claim)
      : new Response(null, { status: 404 })
  })
]
