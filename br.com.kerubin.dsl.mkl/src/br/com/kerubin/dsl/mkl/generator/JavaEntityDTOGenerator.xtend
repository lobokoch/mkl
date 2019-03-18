package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BasicTypeReference
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.ManyToMany
import br.com.kerubin.dsl.mkl.model.ManyToOne
import br.com.kerubin.dsl.mkl.model.OneToMany
import br.com.kerubin.dsl.mkl.model.OneToOne
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.UUIDType

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityDTOGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateDTO]
	}
	
	def generateDTO(Entity entity) {
		val basePakage = clientGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityDTOName + '.java'
		generateFile(entityFile, entity.generateEntityDTO)
	}
	
	def CharSequence generateEntityDTO(Entity entity) {
		entity.initializeEntityImports
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public class «entity.toEntityDTOName» {
		
			«entity.generateFields»
			«entity.generateGetters»
			«entity.generateSetters»
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
	
	
	
	def CharSequence generateFields(Entity entity) {
		'''
		«entity.slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		// Bean Validations
		val hasNotBlankValidation = !slot.isUUID && (slot.isRequired && slot.isString)
		val hasNotNullValidation = !slot.isUUID && (slot.isRequired && !slot.isString)
		if (hasNotBlankValidation) {
			entity.addImport('import javax.validation.constraints.NotBlank;')
		}
		if (hasNotNullValidation) {
			entity.addImport('import javax.validation.constraints.NotNull;')
		}
		
		if (slot.isDTOFull) {
			entity.addImport('import ' + slot.asEntity.package + '.' + slot.asEntity.toEntityDTOName + ';')
		}
		else if (slot.isDTOLookupResult) {
			entity.addImport('import ' + slot.asEntity.package + '.' + slot.asEntity.toEntityLookupResultDTOName + ';')
		}
		else if (slot.isEnum) { 
			entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		'''
		«IF hasNotBlankValidation»«slot.buildFieldRequiredValidationAnnotation('NotBlank')»«ENDIF»
		«IF hasNotNullValidation»«slot.buildFieldRequiredValidationAnnotation('NotNull')»«ENDIF»
		«IF slot.isToMany»
		private java.util.List<«slot.toJavaTypeDTO»> «slot.name.toFirstLower»;
		«ELSE»
		private «slot.toJavaTypeDTO» «slot.name.toFirstLower»;
		«ENDIF»
		'''
	}
	
	def CharSequence buildFieldRequiredValidationAnnotation(Slot slot, String validationType) {
		val name = slot?.label ?: slot.name
		'''@«validationType»(message="'«name»' é obrigatório.")'''
	}
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		public java.util.List<«slot.toJavaTypeDTO»> get«slot.name.toFirstUpper»() {
		«ELSE»
		public «slot.toJavaTypeDTO» get«slot.name.toFirstUpper»() {
		«ENDIF»
			return «slot.name.toFirstLower»;
		}
		'''
	}
	
	def CharSequence generateSetters(Entity entity) {
		'''
		
		«entity.slots.map[generateSetter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSetter(Slot slot) {
		
		'''
		«IF slot.many && slot.isToMany»
		public void set«slot.name.toFirstUpper»(java.util.List<«slot.toJavaTypeDTO»> «slot.name.toFirstLower») {
		«ELSE»
		public void set«slot.name.toFirstUpper»(«slot.toJavaTypeDTO» «slot.name.toFirstLower») {
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
			«entity.toEntityDTOName» other = («entity.toEntityDTOName») obj;
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
	}
	
	def CharSequence getSlotsEntityImports(Entity entity) {
		'''
		«entity.slots.filter[it.isEntity].map[it | 
			val slotEntity = it.asEntity
			return "import " + slotEntity.package + "." + slotEntity.toEntityName + ";"
			].join('\r\n')»
		'''
	}
	
	def boolean hasRelationship(Slot slot) {
		if (slot.isEntity) {
			return slot.relationship !== null
		}
		false
	}
	
	def boolean existsRelationOneToOne(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof OneToOne]
		exists
	}
	
	def boolean existsRelationManyToOne(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof ManyToOne]
		exists
	}
	
	def boolean existsRelationOneToMany(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof OneToMany]
		exists
	}
	
	def boolean existsRelationManyToMany(Entity entity) {
		val exists = entity.slots.exists[it.relationship instanceof ManyToMany]
		exists
	}
	
	def boolean existsRelation(Entity entity) {
		entity.slots.exists[it.isEntity]
	}
	
	def boolean isUUID(Slot slot) {
		if (slot.slotType instanceof BasicTypeReference) {
			val basicType = (slot.slotType as BasicTypeReference).basicType
			return basicType instanceof UUIDType
		}
		
		false
	}
	
}