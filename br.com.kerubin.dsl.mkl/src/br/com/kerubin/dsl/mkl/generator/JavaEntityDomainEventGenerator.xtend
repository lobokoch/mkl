package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import java.util.List

class JavaEntityDomainEventGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.publishEntityEvents !== null].forEach[generateEntityDomainEvent]
	}
	
	def generateEntityDomainEvent(Entity entity) {
		val slots = entity.getPublishSlots
		if (!slots.isEmpty) {
			val basePakage = clientGenSourceFolder
			val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityEventName + '.java'
			generateFile(entityFile, entity.doGenerateEntityDomainEvent(slots))
		}
	}
	
	def CharSequence doGenerateEntityDomainEvent(Entity entity, Iterable<Slot> slots) {	
		entity.initializeEntityImports
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public class «entity.toEntityEventName» implements DomainEvent {
			
			«entity.buildEventConstants»
			«entity.generateFields(slots)»
			«entity.toEntityEventName.generateConstructor(entity.publishSlots, true, true)»
			«entity.generateGetters(slots)»
			«entity.generateSetters(slots)»
			«entity.generateEquals»
			«entity.generateHashCode»
			«entity.generateToString»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		package + imports + body 
	}
	
	def CharSequence buildEventConstants(Entity entity) {
		val List<String> constants = newArrayList
		if (entity.hasPublishCreated) {
			constants.add(entity.buildEventConstant('created'))
		}
		if (entity.hasPublishUpdated) {
			constants.add(entity.buildEventConstant('updated'))
		}
		if (entity.hasPublishDeleted) {
			constants.add(entity.buildEventConstant('deleted'))
		}
		
		'''
		«constants.join('\n')»
		'''
	}
	
	def String buildEventConstant(Entity entity, String eventName) {
		'''public static final String «entity.toEntityEventConstantName(eventName)» = "«entity.toDtoName.toFirstLower»«eventName.toFirstUpper»";'''.toString
	}
	
	def CharSequence generateFields(Entity entity, Iterable<Slot> slots) {
		'''
		«slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		if (slot.isEntity) {
			//entity.addImport('import java.util.UUID;') // Não precisa
		}
		else if (slot.isEnum) { 
			entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		'''
		«IF slot.isToMany»
		private java.util.List<«slot.toJavaTypeForEntityEvent»> «slot.name.toFirstLower»;
		«ELSE»
		private «slot.toJavaTypeForEntityEvent» «slot.name.toFirstLower»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateGetters(Entity entity, Iterable<Slot> slots) {
		'''
		
		«slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		public java.util.List<«slot.toJavaTypeForEntityEvent»> get«slot.name.toFirstUpper»() {
		«ELSE»
		public «slot.toJavaTypeForEntityEvent» get«slot.name.toFirstUpper»() {
		«ENDIF»
			return «slot.name.toFirstLower»;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity, Iterable<Slot> slots) {
		'''
		
		«slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		«IF slot.many && slot.isToMany»
		public void set«slot.name.toFirstUpper»(java.util.List<«slot.toJavaTypeForEntityEvent»> «slot.name.toFirstLower») {
		«ELSE»
		public void set«slot.name.toFirstUpper»(«slot.toJavaTypeForEntityEvent» «slot.name.toFirstLower») {
		«ENDIF»
			this.«slot.name.toFirstLower» = «slot.name.toFirstLower»;
		}
		'''
	}
	
	//From https://vladmihalcea.com/the-best-way-to-implement-equals-hashcode-and-tostring-with-jpa-and-hibernate/
	def CharSequence generateEquals(Entity entity) {
		val isOneToManyWithMapsId = entity.id.isOneToOne && entity.id.isRelationRefers
		val id = if (!isOneToManyWithMapsId && entity.id.isEntity) entity.id.asEntity.name + '.get' + entity.id.asEntity.id.name.toFirstUpper + '()' else entity.id.name
		
		'''
		
		@Override
		public boolean equals(Object obj) {
			if (this == obj)
				return true;
			if (obj == null)
				return false;
			if (getClass() != obj.getClass())
				return false;
			«entity.toEntityEventName» other = («entity.toEntityEventName») obj;
			if («id» == null) {
				if (other.«id» != null)
					return false;
			} else if (!«id».equals(other.«id»))
				return false;
			
			return true;
		}
		'''
		
	}
	
	//From: https://vladmihalcea.com/the-best-way-to-implement-equals-hashcode-and-tostring-with-jpa-and-hibernate/
	def CharSequence generateHashCode(Entity entity) {
		'''
		
		@Override
		public int hashCode() {
			return 31;
		}
		'''
		
	}
	
	def CharSequence generateToString(Entity entity) {
		'''
		
		/* 
		@Override
		public String toString() {
			// Enabling toString for JPA entities will implicitly trigger lazy loading on all fields.
		}
		*/
		'''
	}
	
	def void initializeEntityImports(Entity entity) {
		entity.imports.clear
		entity.imports.add('import br.com.kerubin.api.messaging.core.DomainEvent;')
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		«entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')»
		'''
	}
	
}