package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension org.apache.commons.lang3.StringUtils.*

class JavaEntityListFilterGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[ entity |
			//if (entity.hasListFilter) {
				entity.generateListFilter
				entity.generateListFilterPredicate
				entity.generateListFilterPredicateImpl
			//}
		]
	}
	
	def generateListFilter(Entity entity) {
		val basePakage = clientGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterClassName + '.java'
		generateFile(entityFile, entity.generateEntityListFilter)
		entity.imports.clear
	}
	
	def generateListFilterPredicate(Entity entity) {
		val basePakage = serverGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterPredicateName + '.java'
		generateFile(entityFile, entity.generateEntityListFilterPredicate)
		entity.imports.clear
	}
	
	def generateListFilterPredicateImpl(Entity entity) {
		val basePakage = serverGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityListFilterPredicateImplName + '.java'
		generateFile(entityFile, entity.generateEntityListFilterPredicateImpl)
		entity.imports.clear
	}
	
	def CharSequence generateEntityListFilterPredicateImpl(Entity entity) {
		entity.initializeEntityImports
		val varFilter = entity.toEntityListFilterName
		val qEntity = 'Q' + entity.toEntityName.toFirstUpper
		val varQEntity = 'qEntity'
		val slots = entity.slots.filter[it.hasListFilter]
		val hasListFilter = !slots.empty
		
		val package = '''
		package «entity.package»;
		
		'''
		val body = '''
		
		import org.springframework.stereotype.Component;
		import com.querydsl.core.types.Predicate;
		import com.querydsl.core.BooleanBuilder;
		«IF hasListFilter»
		import com.querydsl.core.types.dsl.BooleanExpression;
		«ENDIF»
		
		@Component
		public class «entity.toEntityListFilterPredicateImplName» implements «entity.toEntityListFilterPredicateName» {
			
			@Override
			public Predicate mountAndGetPredicate(«entity.toEntityListFilterClassName» «varFilter») {
				if («varFilter» == null) {
					return null;
				}
				
				«IF hasListFilter»
				«qEntity» «varQEntity» = «qEntity».«entity.toEntityName.toFirstLower»;
				«ENDIF»
				BooleanBuilder where = new BooleanBuilder();
				
				«slots.map[generateFieldPredicate(varFilter, varQEntity)].join('\r\n')»
				
				return where;
			}
		
		}
		
		'''
		
		package + entity.buildImports + body
	}
	
	def CharSequence buildImports(Entity entity) {
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		'''
		imports
	}
	
	def CharSequence generateFieldPredicate(Slot slot, String varFilter, String varQEntity) {
		val isMany = isMany(slot)
		val isNotNull = slot.isNotNull
		val isNull = slot.isNull
		val isBetween = slot.isBetween
		val isEqualTo = slot.isEqualTo
		
		if (isMany) {
			slot.buildFieldPredicateMany(varFilter, varQEntity)			
		}
		else if (isBetween) {
			slot.buildFieldPredicateBetween(varFilter, varQEntity)	
			
		}
		else if (isNotNull || isNull) {
			slot.buildFieldPredicateBoolean(varFilter, varQEntity)
		}
		else if (isEqualTo) {
			slot.buildFieldPredicateIsEqualTo(varFilter, varQEntity)
		}
		
	}
	
	def CharSequence buildFieldPredicateIsEqualTo(Slot slot, String varFilter, String varQEntity) {
		
		// begin isEqualTo
		val pair = slot.getSlotNameAndType
		//val fieldType = pair.key
		val fieldName = pair.value
		// end isEqualTo
		
		val varName = fieldName + IS_EQUAL_TO
		
		//val qFieldName = fieldName.splitByCharacterTypeCamelCase.map[it.toFirstLower].join('.')
		val qFieldName = slot.toFieldAndEntityId
		
		'''
		// Begin field: «fieldName»
		if («varFilter».«fieldName.buildMethodGet» != null) {
			BooleanExpression «varName» = «varQEntity».«qFieldName».eq(«varFilter».«fieldName.buildMethodGet»);
			where.and(«varName»);
		}
		// End field: «fieldName»
		'''
	}
	
	def CharSequence buildFieldPredicateBoolean(Slot slot, String varFilter, String varQEntity) {
		val isNotNull = slot.isNotNull
		val isNull = slot.isNull
		val fieldName = slot.name.toFirstUpper
		
		val isNullStr = 'is' + fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper + '()'
		val isNotNullStr = 'is' + fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper + '()'
		
		val getNullStr = 'get' + fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper + '()'
		val getNotNullStr = 'get' + fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper + '()'
		
		'''
		// Begin field: «fieldName»
		«IF isNotNull && isNull»		
		if ( ! («varFilter».«isNullStr» && «varFilter».«isNotNullStr») ) {
			
			if («varFilter».«getNullStr» != null) {
				if («varFilter».«isNullStr») {
					where.and(«varQEntity».«slot.fieldName».isNull());
				}
				else {
					where.and(«varQEntity».«slot.fieldName».isNotNull());				
				}
			}
			
			if («varFilter».«getNotNullStr» != null) {
				if («varFilter».«isNotNullStr») {
					where.and(«varQEntity».«slot.fieldName».isNotNull());
				}
				else {
					where.and(«varQEntity».«slot.fieldName».isNull());				
				}
			}
			
		}
		«ELSEIF isNull»		
		if («varFilter».«isNullStr») {
			where.and(«varQEntity».«slot.fieldName».isNull());
		}
		else {
			where.and(«varQEntity».«slot.fieldName».isNotNull());				
		}
		«ELSEIF isNotNull»		
		if («varFilter».«isNotNullStr») {
			where.and(«varQEntity».«slot.fieldName».isNotNull());
		}
		else {
			where.and(«varQEntity».«slot.fieldName».isNull());				
		}
		«ENDIF»
		// End field: «fieldName»
		'''
	}
	
	def CharSequence buildFieldPredicateBetween(Slot slot, String varFilter, String varQEntity) {
		val fieldName = slot.fieldName.toFirstUpper
		
		val fieldFrom = 'fieldFrom' + fieldName
		val fieldTo = 'fieldTo' + fieldName
		var String[] labels = slot.listFilter.filterOperator?.label?.split(';')
		if (labels !== null) {
			if (labels.size == 0) {
				labels = #[slot.name + ' inicial', slot.name + ' final']
			}
			else if (labels.size == 1) {
				labels = #[labels.get(0), slot.name + ' final']
			}
		}
		else {
			labels = #[slot.name + ' inicial', slot.name + ' final']
		}
		
		'''
		
		// Begin field: «fieldName»
		«slot.toJavaType» «fieldFrom» = «slot.buildMethodGet(varFilter, BETWEEN_FROM)»;
		«slot.toJavaType» «fieldTo» = «slot.buildMethodGet(varFilter, BETWEEN_TO)»;
		
		if («fieldFrom» != null && «fieldTo» != null) {
			«IF slot.isDate»
			if («fieldFrom».isAfter(«fieldTo»)) {
				throw new IllegalArgumentException("Valor de \"«labels.get(0)»\" não pode ser maior do que valor de \"«labels.get(1)»\".");
			}
			«ENDIF»
			
			BooleanExpression between = «varQEntity».«slot.fieldName».between(«fieldFrom», «fieldTo»);
			where.and(between);
		}
		else {
			if («fieldFrom» != null) {
				where.and(«varQEntity».«slot.fieldName».goe(«fieldFrom»));
			}
			else if («fieldTo» != null) {
				where.and(«varQEntity».«slot.fieldName».loe(«fieldTo»));				
			}
		}
		// End field: «fieldName»
		'''
	}
	
	def CharSequence buildFieldPredicateMany(Slot slot, String varFilter, String varQEntity) {
		slot.ownerEntity.addImport("import org.springframework.util.CollectionUtils;")
		val fieldName = slot.fieldName
		
		'''
		// Begin field: «fieldName»
		if (!CollectionUtils.isEmpty(«varFilter».«slot.buildMethodGet»)) {
			BooleanExpression inExpression = «varQEntity».«fieldName».in(«varFilter».«slot.buildMethodGet»);
			where.and(inExpression);
		}
		// End field: «fieldName»
		'''
	}
	
	def CharSequence generateEntityListFilterPredicate(Entity entity) {
		entity.initializeEntityImports
		
		'''
		package «entity.package»;
		
		import com.querydsl.core.types.Predicate;
		
		public interface «entity.toEntityListFilterPredicateName» {
			
			Predicate mountAndGetPredicate(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName»);
		
		}
		
		'''
	}
	
	def CharSequence generateEntityListFilter(Entity entity) {
		entity.initializeEntityImports
		val slots = entity.slots.filter[it.hasListFilter]
		
		val isEnableDoc = entity.service.isEnableDoc
		if (isEnableDoc) {
			entity.addImport('import io.swagger.annotations.ApiModel;')
			if (!slots.empty) {
				entity.addImport('import io.swagger.annotations.ApiModelProperty;')
			}
		}
		val title = entity.title
		
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		«IF isEnableDoc»
				
		@ApiModel(description = "Details about list filter of «title»")
		«ENDIF»
		public class «entity.toEntityListFilterClassName» {
		
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
	
	def CharSequence generateField(Slot slot) {
		val entity = slot.ownerEntity
		
		if (slot.isDate) {
			entity.addImport("import org.springframework.format.annotation.DateTimeFormat;")
		}
		else if(slot.isEnum) {
			entity.addImport('import ' + slot.asEnum.enumPackage + ';')
		}
		
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
		
		val isEqualTo = slot.isEqualTo
		
		// begin isEqualTo
		val pair = slot.getSlotNameAndType
		val fieldType = pair.key
		var fieldName = pair.value
		// end isEqualTo
		
		val isEnableDoc = entity.service.isEnableDoc
		val title = slot.title
		
		var position = slot.position
		
		'''
		«IF isEqualTo»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title»", position = «position»)
		«ENDIF»
		private «fieldType» «fieldName»;
		«ENDIF»
		«IF isMany»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title»", position = «position»)
		«ENDIF»
		private java.util.List<«slot.toJavaType»> «slot.name.toFirstLower»;
		«ELSEIF isNotNull && isNull»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title» is not null", position = «position»)
		«ENDIF»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title» is null", position = «position»)
		«ENDIF»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isNotNull»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title» is not null", position = «position»)
		«ENDIF»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»;
		«ELSEIF isNull»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«title» is null", position = «position»)
		«ENDIF»
		private Boolean «slot.name.toFirstLower»«FilterOperatorEnum.IS_NULL.getName.toFirstUpper»;
		«ELSEIF isBetween»
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "Is between from «title»", position = «position»)
		«ENDIF»
		private «slot.toJavaType» «slot.name.toFirstLower»«BETWEEN_FROM»;
		
		«IF slot.isDate»
		@DateTimeFormat(pattern = "yyyy-MM-dd")
		«ENDIF»
		«IF isEnableDoc»
		@ApiModelProperty(notes = "Is between to «title»", position = «position»)
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
		
		val isEqualTo = slot.isEqualTo
		
		// begin isEqualTo
		val pair = slot.getSlotNameAndType
		val fieldType = pair.key
		var fieldName = pair.value
		// end isEqualTo
		
		'''
		«IF isEqualTo»
		«fieldName.genGetMethod(fieldType)»
				
		«fieldName.genSetMethod(fieldType)»
		«ENDIF»
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