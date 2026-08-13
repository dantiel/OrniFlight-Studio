###
# ORNIFLIGHT STUDIO — Simulation Engine Singleton
#
# One engine instance shared by the simulation loop, the engine
# store (config + actions) and the integration bridge. Import
# this module — never construct OrnithopterModel twice.
###
import { OrnithopterModel } from './OrnithopterModel.coffee'

engine = new OrnithopterModel()
engine.connect()

export { engine }
