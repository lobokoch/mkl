package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityListFilterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private val final BETWEEN_FROM = 'From'
	private val final BETWEEN_TO = 'To'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateListFilter]
	}
	
	def generateListFilter(Entity entity) {
		if (entity.hasListFilter) {
			val basePakage = clientGenSourceFolder
			val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterName + '.java'
			generateFile(entityFile, entity.generateEntityListFilter)
		}
	}
	
	def CharSequence generateEntityListFilter(Entity entity) {
		entity.initializeEntityImports
		val slots = entity.slots.filter[it.hasListFilter]
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		public class «entity.toEntityListFilterName» {
		
			«slots.generateFields»
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		
		package + imports + body 
	}
	
	
	def CharSequence generateFields(Iterable<Slot> slots) {
		'''
		«slots.map[generateField].join('\r\n')»
		
		«slots.map[generateGetterAndSetter].join('\r\n')»
		'''
		
	}
	
	private def boolean isNotNull(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
	} 
	
	private def boolean isNull(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NULL) ||
			slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.IS_NOT_NULL_IS_NULL)
	} 
	
	private def boolean isMany(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.MANY)
	} 
	
	private def boolean isBetween(Slot slot) {
		slot.listFilter.filterOperator.filterOperatorEnum.equals(FilterOperatorEnum.BETWEEN)
	} 
	
	def CharSequence generateField(Slot slot) {
		val entity = slot.ownerEntity
		
		if (slot.isDate) {
			entity.addImport("import org.springframework.format.annotation.DateTimeFormat;")
		}
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
		
		'''
		«IF isMany»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private java.util.List<«slot.toJavaType»> «slot.name.toFirstLower»;
		«ELSEIF isNotNull && isNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isNotNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		«ELSEIF isNull»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isBetween»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_FROM»;
		
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_TO»;
		«ENDIF»
		'''
	}
	
	def CharSequence generateGetterAndSetter(Slot slot) {
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
		
		'''
		«IF isMany»
		«slot.getListMethod»
		
		«slot.getSetListMethod»
		«ELSEIF isNotNull && isNull»
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
		
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
		
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
		
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
		
		«ELSEIF isNotNull»
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
				
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NOT_NULL.getName())»
		«ELSEIF isNull»
		«slot.getGetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
				
		«slot.getSetMethodAsBoolean(FilterOperatorEnum.IS_NULL.getName())»
		«ELSEIF isBetween»
		«slot.getGetMethod(BETWEEN_FROM)»
		
		«slot.getSetMethod(BETWEEN_FROM)»
		
		«slot.getGetMethod(BETWEEN_TO)»
		
		«slot.getSetMethod(BETWEEN_TO)»
		«ENDIF»
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
	
	
	
}