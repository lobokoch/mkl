package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.ModelFactory
import br.com.kerubin.dsl.mkl.model.Service
import br.com.kerubin.dsl.mkl.model.Slot

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class ServiceBoosterImpl implements ServiceBooster {
	
	Service service
	
	override void augmentService(Service service) {
		this.service = service
		val entities = service.elements.filter(Entity)
		entities.augmentEntities
	}
	
	private def augmentEntities(Iterable<Entity> entities) {
		entities.forEach[augmentEntity]
		entities.forEach[hideEntityIds]
	}
	
	private def void hideEntityIds(Entity entity) {
		if (entity.id.hidden === null) {
			entity.id.hidden = true
		}
	}
	
	private def void augmentEntity(Entity entity) {
		val entityHasAutoComplete = entity.hasAutoComplete;
		
		if (!entity.hasId) {
			entity.createImplicitId
		}
		
		if (! entity.id.hasAutoComplete) {
			entity.id.createAutoCompleteOnlyResutForSlot
		}
		
		if (! entity.id.hasGrid) {
			entity.id.createGridHiddenForSlot
		}
		
		if (! entity.id.hasLabel) {
			entity.id.label = "#id"
		}
		
		// If an entity slot doesn't has a label, it takes the label from his entity definition.
		entity.slots.filter[isEntity].forEach[
			if (!it.hasLabel) {
				it.label = it.asEntity.label
			}
		]
		
		if (!entityHasAutoComplete) {
			val slot = entity.slots.findFirst[it.isString]
			if (slot !== null) {
				slot.createAutoCompleteForSlot
			}
		}
		
		if (entity.publishEntityEvents !== null) {
			entity.id.publish = true // id is implicit
		}
		
		if (entity.hasSubscribeDeleted && !entity.slots.exists[it.name == DELETED_FIELD_NAME]) { // Creates an implicit deleted slot.
			val deletedSlot = ModelFactory.eINSTANCE.createSlot
			deletedSlot.name = DELETED_FIELD_NAME
			deletedSlot.label = DELETED_FIELD_LABEL
			//deletedSlot.web.label = DELETED_FIELD_LABEL
			deletedSlot.implicit = true
			deletedSlot.hidden = true
			deletedSlot.optional = true
			val basicTypeReference = ModelFactory.eINSTANCE.createBasicTypeReference
			basicTypeReference.basicType = ModelFactory.eINSTANCE.createBooleanType
			deletedSlot.slotType = basicTypeReference
			
			entity.slots.add(deletedSlot)
		}
		
		if (entity.isAuditing) {
			entity.createAuditingFields
		}
	}
	
	def void createImplicitId(Entity entity) {
		val idSlot = createImplicitId
		entity.slots.add(0, idSlot)
	}
	
	def Slot createImplicitId() {
		val slot = ModelFactory.eINSTANCE.createSlot
		slot.name = 'id'
		slot.label = '#id'
		slot.implicit = true
		slot.hidden = true
		val basicTypeReference = ModelFactory.eINSTANCE.createBasicTypeReference
		basicTypeReference.basicType = ModelFactory.eINSTANCE.createUUIDType
		slot.slotType = basicTypeReference
		slot
	}
	
	def void getCreateAuditingFields(Entity entity) {
		val createdBy = createAuditingField('createdBy', false);
		entity.slots.add(createdBy)
		
		val createdDate = createAuditingField('createdDate', true);
		entity.slots.add(createdDate)
		
		val lastModifiedBy = createAuditingField('lastModifiedBy', false);
		entity.slots.add(lastModifiedBy)
		
		val lastModifiedDate = createAuditingField('lastModifiedDate', true);
		entity.slots.add(lastModifiedDate)
	}
	
	def Slot createAuditingField(String name, boolean isDate) {
		val slot = ModelFactory.eINSTANCE.createSlot
		slot.name = name
		slot.label = slot.name
		slot.implicit = true
		slot.mapped = true
		slot.hidden = true
		slot.optional = true
		val basicTypeReference = ModelFactory.eINSTANCE.createBasicTypeReference
		if (isDate) {
			basicTypeReference.basicType = ModelFactory.eINSTANCE.createDateTimeType
		}
		else {
			basicTypeReference.basicType = ModelFactory.eINSTANCE.createStringType
		}
		slot.slotType = basicTypeReference
		slot
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