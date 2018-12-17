package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Service
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.ModelFactory

class ServiceBoosterImpl implements ServiceBooster {
	
	Service service
	
	override void augmentService(Service service) {
		this.service = service
		val entities = service.elements.filter(Entity)
		entities.augmentEntities
	}
	
	private def augmentEntities(Iterable<Entity> entities) {
		entities.forEach[addEntityDefaultAutoComplete]
	}
	
	private def void addEntityDefaultAutoComplete(Entity entity) {
		if (! entity.id.hasAutoComplete) {
			entity.id.createAutoCompleteOnlyResutForSlot
		}
		
		if (! entity.id.hasGrid) {
			entity.id.createGridHiddenForSlot
		}
		
		val slot = entity.firstSlot
		if (!slot.hasAutoComplete && slot !== entity.id) {
			slot.createAutoCompleteForSlot
		}
	}
	
	private def createAutoCompleteForSlot(Slot slot) {
		val autoComplete = ModelFactory.eINSTANCE.createAutoComplete
		autoComplete.key = true
		autoComplete.result = true
		slot.autoComplete = autoComplete
	}
	
	private def createAutoCompleteOnlyResutForSlot(Slot slot) {
		val autoComplete = ModelFactory.eINSTANCE.createAutoComplete
		autoComplete.key = false
		autoComplete.result = true
		slot.autoComplete = autoComplete
	}
	
	private def createGridHiddenForSlot(Slot slot) {
		val grid = ModelFactory.eINSTANCE.createGrid
		grid.slotIsHidden = true
		slot.grid = grid
	}
	
}