package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.model.Entity

// import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.SmallintType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import br.com.kerubin.dsl.mkl.model.ByteType
import org.apache.commons.lang3.RandomStringUtils
import java.util.Random
import br.com.kerubin.dsl.mkl.generator.ServiceBoosterImpl
import br.com.kerubin.dsl.mkl.model.Service

class TestUtils {
	
	static val ACTUAL = 'actual'
	
	def static buildEntityManagerFlush() {
		'''
		em.flush();
		'''
	}
	
	def static CharSequence buildAssertThatActualIsNotNull() {
		ACTUAL.buildAssertThatIsNotNull
	}
	
	def static CharSequence buildAssertThatIsNotNull(String varName) {
		'''
		assertThat(«varName»).isNotNull();
		'''
	}
	
	def static CharSequence buildAssertThatEntityAsVarIdIsNotNull(Entity entity, String varName) {
		val getField = entity.id.buildMethodGet
		
		'''
		assertThat(«varName».«getField»).isNotNull();
		'''
	}
	
	def static CharSequence buildAssertThatEntitySlotIdIsNotNull(Slot slot, String varName) {
		val entity = slot.asEntity
		val idGetMethod = entity.id.buildMethodGet
		
		'''
		assertThat(«varName».«slot.buildMethodGet».«idGetMethod»).isNotNull();
		'''
	}
	
	def static CharSequence getIdAsString(Entity entity) {
		'''"«entity.id.fieldName»"'''
	}
	
	def static CharSequence getIgnoredFields(Entity entity) {
		val auditinFields = ServiceBoosterImpl.ENTITY_AUDITING_FIELDS.map['"' + it + '"'].join(', ')
		
		'''«entity.getIdAsString»«IF entity.isAuditing», «auditinFields»«ENDIF»'''
	}
	
	def static CharSequence buildAssertThatEntityAsVarIsEqualToIgnoringGivenFields(Entity entity, String varName) {
		val fieldName = entity.fieldName
		
		'''
		assertThat(«varName»).isEqualToIgnoringGivenFields(«fieldName», «entity.getIgnoredFields»);
		'''
	}
	
	def static CharSequence buildAssertThatIsEqualToIgnoringGivenFields(Slot slot, String varName) {
		val entity = slot.ownerEntity
		val getField = slot.buildMethodGet
		val fieldName = entity.fieldName
		
		'''
		assertThat(«varName».«getField»).isEqualToIgnoringGivenFields(«fieldName».«getField», «entity.getIgnoredFields»);
		'''
	}
	
	def static buildAssertEntityFKsIsEqualToIgnoringGivenFields(Slot slot, String varName) {
		'''
		
		«slot.buildAssertThatEntitySlotIdIsNotNull(varName)»
		«slot.buildAssertThatIsEqualToIgnoringGivenFields(varName)»
		
		'''
	}
	
	def static buildEntityCheckActualWithDTO(Entity entity) {
		'''
		«buildAssertThatActualIsNotNull»
		«entity.buildAssertThatEntityAsVarIdIsNotNull(ACTUAL)»
		«entity.buildAssertThatEntityAsVarIsEqualToIgnoringGivenFields(ACTUAL)»
		
		«entity.slots.filter[it.isEntity].map[it.buildAssertEntityFKsIsEqualToIgnoringGivenFields(ACTUAL)].join»
		
		'''
	}
	
	def static CharSequence buildEntityToDTOAsActual(Entity entity) {
		entity.buildEntityToDTO(ACTUAL)
	}
	
	def static CharSequence buildEntityToDTO(Entity entity, String targetVar) {
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val toDTO = 'convertEntityToDto'
		
		'''
		«entityDTOName» «targetVar» = «entityDTOVar»DTOConverter.«toDTO»(«entityVar»);
		'''
	}
	
	def static CharSequence buildServiceCreateFromDTO(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		//val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val entityServiceVar = entity.toServiceName.toFirstLower
		//val idVar = entity.id.name.toFirstLower
		//val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		//val toDTO = 'convertEntityToDto'
		val toEntity = 'convertDtoToEntity'
		
		'''
		«entityName» «entityVar» = «entityServiceVar».create(«entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
		'''
	}
	
	def static CharSequence buildNewEntityDTOVar(Entity entity) {
		val name = entity.name
		val fieldName = entity.fieldName
		'''«name» «fieldName» = new «name»();'''
	}
	
	def static getEntityParamFieldName(Entity entity) {
		entity.name.toFirstLower + "EntityParam"
	}
	
	def static CharSequence buildNewEntityVar(Entity entity) {
		val name = entity.toEntityName
		val fieldName = entity.getEntityParamFieldName
		'''«name» «fieldName» = new«name»();'''
	}
	
	def static CharSequence buildNewEntityWithVar(Entity entity) {
		val name = entity.toEntityName
		val fieldName = entity.entityFieldName
		'''«name» «fieldName» = new «name»();'''
	}
	
	def static CharSequence buildNewEntityLookupResultVar(Slot slot) {
		val entity = slot.asEntity
		val name = entity.toEntityLookupResultDTOName
		val fieldName = slot.fieldName
		val entityFieldName = entity.entityParamFieldName
		// PlanoContaLookupResult planoContas = new PlanoContaLookupResult(planoContaEntity);
		'''«name» «fieldName» = new«name»(«entityFieldName»);'''
	}
	
	def static CharSequence buildNewEntityLookupResultWithVar(Slot slot) {
		val entity = slot.asEntity
		val name = entity.toEntityLookupResultDTOName
		val fieldName = slot.fieldName
		val entityFieldName = entity.entityFieldName
		// PlanoContaLookupResult planoContas = new PlanoContaLookupResult(planoContaEntity);
		'''«name» «fieldName» = new «name»(«entityFieldName»);'''
	}
	
	
	def static CharSequence buildNewEntityMethod(Entity entity) {
		var name = entity.toEntityName
		val fieldName = entity.entityFieldName
		
		'''
		
		private «name» new«name»() {
			«entity.buildNewEntityWithVar»
			
			«entity.slots.filter[!it.isAuditingSlot].map[generateSetterForTest].join»
			
			«fieldName» = em.persistAndFlush(«fieldName»);
			
			return «fieldName»;
		}
		'''
	}
	
	def static CharSequence buildNewEntityLookupResultMethod(Entity entity) {
		val lookupResultName = entity.toEntityLookupResultDTOName
		val entityFieldName = entity.entityFieldName
		val fieldName = entity.fieldName
		val slots = entity.getEntityLookupResultSlots
		
		'''
		
		private «lookupResultName» new«lookupResultName»(«entityFieldName.toFirstUpper» «entityFieldName») {
			«lookupResultName» «fieldName» = new «lookupResultName»();
			
			«slots.map[generateSetterForLookupResult].join»
			
			return «fieldName»;
		}
		'''
	}
	
	def static CharSequence generateSetterForLookupResult(Slot slot) {
		val entity = slot.ownerEntity
		val slotName = slot.name.toFirstUpper
		
		'''
		«entity.fieldName».set«slotName»(«entity.entityFieldName».get«slotName»());
		'''
	}
	
	def static CharSequence generateSetterForTest(Slot slot) {
		val entity = slot.ownerEntity
		
		'''
		«entity.entityFieldName».set«slot.name.toFirstUpper»(«slot.generateRandomTestValueForDTO»);
		'''
	}
	
	def static CharSequence generateSettersForDTO(Entity entity) {
		val slots = entity.slots.filter[!it.isAuditingSlot]
		'''
		«slots.map[generateSetterForDTO].join»
		'''
	}
	
	def static CharSequence generateSetterForDTO(Slot slot) {
		val entity = slot.ownerEntity
		val fieldName = entity.fieldName
		
		'''
		«IF slot.isEntity»
		
		«slot.asEntity.buildNewEntityVar»
		«slot.buildNewEntityLookupResultVar»
		«fieldName».set«slot.name.toFirstUpper»(«slot.fieldName»);
		
		«ELSE»
		«fieldName».set«slot.name.toFirstUpper»(«slot.generateRandomTestValueForDTO»);
		«ENDIF»
		'''
	}
	
	def static CharSequence generateRandomTestValueForDTO(Slot slot) {
		val basicType = slot.basicType
		if (basicType instanceof StringType) {
			val length = if (slot.length > 30) 30 else slot.length 
			val chars = RandomStringUtils.randomAlphabetic(length - 1) + ' ' 
			var value = RandomStringUtils.random(length, chars).trim
			
			// Must remove white spaces in the begining. 
			while (value.length < length) {
				value = RandomStringUtils.random(length, chars).trim
			} 
			'''"«value»"'''
		}
		else if (basicType instanceof IntegerType) {
			val ran = new Random();
			ran.nextInt + ''
		}
		else if (basicType instanceof SmallintType) {
			val ran = new Random();
			ran.nextInt(java.lang.Short.MAX_VALUE) + ''
		}
		else if (basicType instanceof DoubleType) {
			val ran = new Random();
			ran.nextDouble + ''
		}
		else if (basicType instanceof MoneyType) {
			val ran = new Random();
			val a = ran.nextInt(java.lang.Short.MAX_VALUE)
			val b = ran.nextInt(java.lang.Short.MAX_VALUE)
			'''new java.math.BigDecimal("«a».«b»")'''
		}
		else if (basicType instanceof BooleanType) {
			val ran = new Random();
			if (slot.hasDefaultValue) slot.defaultValue else ran.nextBoolean + ''
		}
		else if (basicType instanceof DateType) {
			'''java.time.LocalDate.now()'''
		}
		else if (basicType instanceof TimeType) {
			'''java.time.LocalTime.now()'''
		}
		else if (basicType instanceof DateTimeType) {
			// "java.util.Date"
			'''java.time.LocalDateTime.now()'''
		}
		else if (basicType instanceof UUIDType) {
			'''java.util.UUID.randomUUID()'''
		}
		else if (basicType instanceof ByteType) {
			'''"Unit tests".getBytes()'''
		}
		else {
			if (slot.isEnum) {
				val asEnum = slot.asEnum
				if (asEnum.hasDefault) {
					val result = asEnum.items.get(asEnum.defaultIndex).name
					return asEnum.name + '.' + result.toString
				} else {
					val ran = new Random();
					val index = ran.nextInt(asEnum.items.size)
					val result = asEnum.items.get(index).name
					return asEnum.name + '.' + result.toString
				} 
			} // slot.isEnum
			else if (slot.isEntity && slot.ownerEntity.isNotSameName(slot.asEntity)) {
				'''new«slot.asEntity.entityFieldName.toFirstUpper»()'''
			}
			else {
				'''null'''
			}
		}
		
	}
	
	def static void resolveEntityImports(Entity entitySource, Entity entityTarget) {
		entitySource.resolveSlotsEntityImports(entityTarget)
		entitySource.resolveEntityDTOLookupResultImports(entityTarget)
		entitySource.resolveEntityEnumImports(entityTarget)
	}
	
	def static void resolveSlotsEntityImports(Entity entitySource, Entity entityTarget) {
		entitySource.slots.filter[isEntity].forEach[
			val slotEntity = it.asEntity
			entityTarget.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityName + ';')
		]
	}
	
	def static void resolveEntityDTOLookupResultImports(Entity entitySource, Entity entityTarget) {
		entitySource.slots.filter[isDTOLookupResult].forEach[
			val slotEntity = it.asEntity
			entityTarget.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityLookupResultDTOName + ';')
		]
	}
	
	def static void resolveEntityEnumImports(Entity entitySource, Entity entityTarget) {
		entitySource.slots.filter[isEnum].forEach[
			val asEnum = it.asEnum
			entityTarget.addImport('import ' + asEnum.enumPackage + ';')
		]
	}
	
	def static void resolveEntityImports(Entity entity) {
		entity.resolveSlotsEntityImports
		entity.resolveEntityDTOLookupResultImports
		entity.resolveEntityEnumImports
		
	}
	
	def static void resolveSlotsEntityImports(Entity entity) {
		entity.slots.filter[isEntity].forEach[
			val slotEntity = it.asEntity
			entity.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityName + ';')
		]
	}
	
	def static void resolveEntityDTOLookupResultImports(Entity entity) {
		entity.slots.filter[isDTOLookupResult].forEach[
			val slotEntity = it.asEntity
			entity.addImport('import ' + slotEntity.package + '.' + slotEntity.toEntityLookupResultDTOName + ';')
		]
	}
	
	def static void resolveEntityEnumImports(Entity entity) {
		entity.slots.filter[isEnum].forEach[
			val asEnum = it.asEnum
			entity.addImport('import ' + asEnum.enumPackage + ';')
		]
	}
	
	def static toRepositoryNameForTest(Entity entity) {
		var name = entity.name.toFirstUpper 
		name += "TestRepository"
		name
	}
	
	def static String toServiceEntityBaseTestClassName(Service service) {
		service.domain.toFirstUpper + service.name.toFirstUpper + "BaseEntityTest"
	}
	
	def static String toServiceEntityBaseTestConfigClassName(Service service) {
		val baseName = service.toServiceEntityBaseTestClassName
		val name = baseName + 'Config'
		name
	}
	
}