package br.com.kerubin.dsl.mkl.generator.test

import br.com.kerubin.dsl.mkl.generator.BaseGenerator
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.model.Entity
import java.util.ArrayList
import java.util.List

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.test.TestUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.JavaEntityServiceGenerator.*
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.Rule

class JavaEntityServiceTestGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.canGenerateTest && !it.isOneToManyChild].forEach[generateTest]
	}
	
	def generateTest(Entity entity) {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceTestName + '.java'
		generateFile(fileName, entity.generateEntityTest)
	}
	
	def CharSequence generateEntityTest(Entity entity) {
		
		entity.imports.clear
		
		val fkSlots = entity.getEntitySlots
		val fkSlotsDistinct = fkSlots.getDistinctSlotsByEntityName
		
		entity.resolveEntityImports
		
		val dependenciesSource = new StringBuilder() 
		
		entity.generateTestDependencies(dependenciesSource, new ArrayList())
		
		val ruleMakeCopies = entity.ruleMakeCopies
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		«entity.generateTestAnnotations»
		public class «entity.toServiceTestName» extends «service.toServiceEntityBaseTestClassName» {
			
			«entity.generateIgnoredFieldsConstant»
			
			«entity.generateTestConfiguration»
			
			«entity.generateFields(fkSlotsDistinct)»
			
			// BEGIN CREATE TESTS
			«entity.generateCreateTests»
			// END CREATE TESTS
			
			// BEGIN READ TESTS
			«entity.generateReadTests»
			// END READ TESTS
			
			// BEGIN UPDATE TESTS
			«entity.generateUpdateTests»
			// END UPDATE TESTS
			
			// BEGIN DELETE TESTS
			«entity.generateDeleteTests»
			// END DELETE TESTS
			
			// BEGIN LIST TESTS
			«entity.generateListTests»
			// END LIST TESTS
			
			«IF entity.hasAutoComplete»
			// BEGIN Autocomplete TESTS
			«entity.generateAutoCompleteTests»
			// END Autocomplete TESTS
			«ENDIF»
			
			«IF entity.hasListFilterMany»
			// BEGIN ListFilter Autocomplete TESTS
			«entity.generateListFilterAutoCompleteTests»
			// END ListFilter Autocomplete TESTS
			«ENDIF»
			
			«IF !fkSlots.empty»
			// BEGIN Relationships Autocomplete TESTS
			«fkSlots.generateFKAutoCompleteTests»
			// END Relationships Autocomplete TESTS
			«ENDIF»
			
			// BEGIN tests for Sum Fields
			«IF entity.hasSumFields»
			«entity.generateSumFieldTests»
			«ENDIF»
			// END tests for Sum Fields
			
			// BEGIN tests for Sum Fields
			«IF !ruleMakeCopies.isEmpty»
			«ruleMakeCopies.generateRuleMakeCopiesTests»
			«ENDIF»
			// END tests for Sum Fields
			
			// BEGIN TESTS DEPENDENCIES
			«dependenciesSource»
			// END TESTS DEPENDENCIES
		
		}
		'''
		
		val imports = '''
		«entity.imports.map[it].join('\r\n')»
		
		import org.junit.Test;
		import static org.assertj.core.api.Assertions.assertThat;
		import «service.servicePackage».«service.toServiceEntityBaseTestClassName»;
		
		'''
		
		package + imports + body 
		
	}
	
	def void generateTestDependencies(Entity entity, StringBuilder source, List<String> visited) {
		
		if (!visited.contains(entity.name)) {
			var result = entity.buildNewEntityMethod
			result = result + '' + entity.buildNewEntityLookupResultMethod
			source.append(result)
			
			visited.add(entity.name)
			
			val slots = entity.slots.filter[it.isEntity]
			slots.forEach[it.asEntity.generateTestDependencies(source, visited)]
		}
		
	}

	
	def CharSequence generateCreateTests(Entity entity) {
		val sb = new StringBuilder
		
		sb.append(entity.generateCreateTest1)
		sb.append(entity.generateCreateTest2)
		
		'''
		«sb.toString»
		'''
	}
	
	def CharSequence generateUpdateTests(Entity entity) {
		val sb = new StringBuilder
		
		sb.append(entity.generateUpdateTest1)
		sb.append(entity.generateUpdateTest2)
		
		'''
		«sb.toString»
		'''
	}
	
	def CharSequence generateReadTests(Entity entity) {
		val readTest1 = entity.generateReadTest1
		readTest1
	}
	
	def CharSequence generateDeleteTests(Entity entity) {
		val deleteTest1 = entity.generateDeleteTest1
		deleteTest1
	}
	
	def CharSequence generateListTests(Entity entity) {
		val hasSomeListFilterMany = entity.slots.exists[it.isListFilterMany]
		val hasSomeSort = entity.slots.exists[it.hasSort]
		
		var CharSequence test1 = ''
		var CharSequence test2 = ''
		var CharSequence test3 = ''
		
		if (hasSomeListFilterMany) {
			entity.addImport('import java.util.List;')
			entity.addImport('import java.util.ArrayList;')
			entity.addImport('import java.util.stream.Collectors;')
			entity.addImport('import org.springframework.data.domain.Pageable;')
			entity.addImport('import org.springframework.data.domain.Page;')
			entity.addImport('import org.springframework.data.domain.PageRequest;')
			entity.addImport(service.importPageResult)
			
			test1 = entity.generateListTest1
			test3 = entity.generateListTest3
		}
		
		if (hasSomeSort) {
			entity.addImport('import java.util.Collections;')
			entity.addImport('import org.springframework.data.domain.Sort;')
			
			test2 = entity.generateListTest2
		}
		
		'''
		«test1»
		«test3»
		«test2»
		'''
	}
	
	def CharSequence generateListTest1(Entity entity) {
		val firstListFilterSlot = entity.slots.filter[it.isListFilterMany].head
		val size = 33;
		val resultSize = 7;
		
		val testMethodName = '''testList_FilteringBy«firstListFilterSlot.fieldName.toFirstUpper»'''
		
		val subject = firstListFilterSlot.fieldName + 'ListFilter'
		
		'''
		
		@Test
		public void «testMethodName»() {
			«generateCallResetNextDate»
			
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateNewEntityListFilterVar»
			
			«entity.generateGetRandomItemsOf(resultSize)»
			
			«firstListFilterSlot.generateAndSetListFilterToSlot»
			
			«generatePageableWithoutSort(0, size)»
			«entity.generateTestVisitorEvent(testMethodName, subject, true)»
			«entity.generateCallServiceList»
			«entity.generateTestVisitorEvent(testMethodName, 'page', false)»
			
			«entity.generatePageContentMapToPageResult»
			
			«firstListFilterSlot.assertThatSlotListFilterResultContent(resultSize)»
			
			«generateAssertThatPageResult(1, resultSize, resultSize)»
			
		}
		'''
	}
	
	def CharSequence generateSumFieldTests(Entity entity) {
		
		val sb = new StringBuilder
		
		sb.append(entity.generateSumFieldTest1)
		
		'''
		«sb.toString»
		'''
	}
	
	def CharSequence generateRuleMakeCopiesTests(Iterable<Rule> ruleMakeCopies) {
		
		'''
		«ruleMakeCopies.map[generateRuleMakeCopiesTest].join»
		'''
	}
	
	def CharSequence generateRuleMakeCopiesTest(Rule rule) {
		
		val actionName = rule.getRuleActionMakeCopiesName.toString
		val entity = (rule.owner as Entity)
		
		val entityName = entity.toEntityName
		
		val referenceField = rule.getRuleMakeCopiesReferenceField
		val repositoryVar = entity.toRepositoryName.toFirstLower
		
		val numberOfCopies1 = 1;
		val numberOfCopies11 = 11;
		
		val testMethodName = '''test«actionName.toFirstUpper»_«numberOfCopies1»Copy'''
		
		'''
		
		@Test
		public void «testMethodName»() {
			«entityName» baseEntity = «entity.generateNewEntityRecord»;
			
			«rule.generateAndSetEntityMakeCopies(/*numberOfCopies=*/numberOfCopies1, /*referenceFieldInterval=*/30)»
			«entity.generateTestVisitorEvent(testMethodName, true)»
			«rule.generateCallActionEntityMakeCopies»
			«entity.generateTestVisitorEvent(testMethodName, false)»
			
			«rule.generateEntityMakeCopiesExpected(numberOfCopies1)»
			
			List<«entityName»> actual = «repositoryVar».findAll();
			
			«referenceField.generateEntityListByField('actual')»
			«referenceField.generateEntityListByField('copies')»
			
			«generateAssertThatListIsEqual('actual', 'copies', /*size=*/numberOfCopies1 + 1)»
			
		}
		
		@Test
		public void test«actionName.toFirstUpper»_«numberOfCopies11»Copies() {
			«entityName» baseEntity = «entity.generateNewEntityRecord»;
						
			«rule.generateAndSetEntityMakeCopies(/*numberOfCopies=*/numberOfCopies11, /*referenceFieldInterval=*/30)»
			
			«rule.generateCallActionEntityMakeCopies»
			
			«rule.generateEntityMakeCopiesExpected(numberOfCopies11)»
			
			List<«entityName»> actual = «repositoryVar».findAll();
			
			«referenceField.generateEntityListByField('actual')»
			«referenceField.generateEntityListByField('copies')»
			
			«generateAssertThatListIsEqual('actual', 'copies', /*size=*/numberOfCopies11 + 1)»
		}
		'''
		
	}
	
	def CharSequence generateSumFieldTest1(Entity entity) {
		
		val sumFieldsName = entity.toEntitySumFieldsName
		val getEntitySumFields = 'get' + sumFieldsName
		val entityServiceVar = entity.toServiceName.toFirstLower
		
		val size = 2;
		val resultSize = 2;
		
		val testMethodName = '''test«getEntitySumFields.toFirstUpper»'''
		
		'''
		
		@Test
		public void «testMethodName»() {
			«generateCallResetNextDate»
			
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateNewEntityListFilterVar»
			
			«entity.generateGetRandomItemsOf(resultSize)»
			
			«sumFieldsName» expected = new «sumFieldsName»();
			«entity.sumFieldSlots.map[generateSumFieldForTest].join»
			«entity.generateTestVisitorEvent(testMethodName, 'listFilter', true)»
			«sumFieldsName» actual = «entityServiceVar».«getEntitySumFields»(listFilter);
			«entity.generateTestVisitorEvent(testMethodName, 'actual', false)»
			
			«buildAssertThatIsEqualToComparingFieldByField»
		}
		'''
	}
	
	def CharSequence generateListTest3(Entity entity) {
		
		entity.addImport('import java.util.Arrays;')
		
		val firstListFilterSlot = entity.slots.filter[it.isListFilterMany].head
		val size = 33;
		
		val testMethodName = '''testList_FilteringBy«firstListFilterSlot.fieldName.toFirstUpper»WithoutResults'''
		
		val subject = firstListFilterSlot.fieldName + 'ListFilter'
		
		'''
		
		@Test
		public void «testMethodName»() {
			«generateCallResetNextDate»
						
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateNewEntityListFilterVar»
			
			«firstListFilterSlot.generateAndSetListFilterToSlotWithFakeData»
			
			«generatePageableWithoutSort(0, size)»
			«entity.generateTestVisitorEvent(testMethodName, subject, true)»
			«entity.generateCallServiceList»
			«entity.generateTestVisitorEvent(testMethodName, 'page', false)»
			
			«entity.generatePageContentMapToPageResult»
			
			«firstListFilterSlot.assertThatSlotListFilterResultContentIsZero»
			
		}
		'''
	}
	
	def CharSequence generateListTest2(Entity entity) {
		val size = 10;
		val sortSlot = entity.slots.filter[it.hasSort].head
		
		val testMethodName = '''testList_SortingBy«sortSlot.fieldName.toFirstUpper»'''
		
		val subject = 'pageable'
		
		'''
		
		@Test
		public void «testMethodName»() {
			«generateCallResetNextDate»
			
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateNewEntityListFilterVar»
			
			«generatePageableAsc(0, size, sortSlot)»
			
			«entity.generateTestVisitorEvent(testMethodName, subject, true)»
			«entity.generateCallServiceList»
			«entity.generateTestVisitorEvent(testMethodName, 'page', false)»
			
			«entity.generatePageContentMapToPageResult»
			
			«sortSlot.generateCollectSlotTestData(TEST_DATA)»
			
			«sortSlot.generateSortAscCollectedSlotTestData»

			«sortSlot.assertThatSortSlotResultContent(size)»
			
			«generateAssertThatPageResult(1, size, size)»
			
		}
		'''
	}
	
	def CharSequence generateReadTest1(Entity entity) {
		val name = entity.toDtoName
		val varName = entity.fieldName
		val entityName = entity.toEntityName
		
		val testMethodName = 'testRead1'
		
		'''
		
		@Test
		public void «testMethodName»() {
			«entityName» expected«entityName» = new«entityName»();
			«entity.id.toJavaType» id = expected«entityName».«entity.id.getMethod2»;
			«name» expected = «varName»DTOConverter.convertEntityToDto(expected«entityName»);
			«entityName» read«entityName» = «varName»Service.read(id);
			«name» actual = «varName»DTOConverter.convertEntityToDto(read«entityName»);
			
			«entity.generateTestVisitorEvent(testMethodName, 'expected', true)»
			«entity.generateTestVisitorEvent(testMethodName, 'actual', false)»
			assertThat(actual).isEqualToComparingFieldByField(expected);
			
		}
		'''
	}
	
	def CharSequence generateDeleteTest1(Entity entity) {
		val entityName = entity.toEntityName
		val fieldName = entity.fieldName
		val expected = 'expected'
		val idVar = 'id'
		
		val testMethodName = 'testDelete1'
		
		'''
		
		@Test
		public void «testMethodName»() {
			«entityName» «expected» = new«entityName»();
			«entity.id.toJavaType» «idVar» = «expected».«entity.id.getMethod2»;
			
			«IF entity.hasPublishEntityEvents»
			«entityName» «fieldName» = «expected»;
			«ENDIF»
			
			«entity.generateEntityManagerFind»
			«entity.generateTestVisitorEvent(testMethodName, 'expected', true)»
			«expected.buildAssertThatIsNotNull»
			«IF entity.hasPublishEntityEvents»
			«entity.generatePublishedEventDoAnswer(EVENT_DELETED)»
			«ENDIF»
			«entity.generateServiceDelete»
			«entity.generatePublishedEventVerify(EVENT_DELETED)»
			
			«entity.generateEntityManagerFind»
			«entity.generateTestVisitorEvent(testMethodName, 'expected', false)»
			«expected.buildAssertThatIsNull»
		}
		'''
	}
	
	def CharSequence generateCreateTest1(Entity entity) {
		
		entity.slots.filter[it.isEntity].forEach[it.asEntity.resolveEntityImports(entity)]
		val rulesFormOnCreate = entity.rulesFormOnCreate
		val imports = entity.imports
		
		val testMethodName = 'testCreateWithAllFields'
		
		'''
		
		@Test
		public void «testMethodName»() throws Exception {
			«entity.buildNewEntityDTOVar»
			
			«entity.generateSettersForDTO»
			«IF entity.hasPublishEntityEvents»
			«entity.generatePublishedEventDoAnswer(EVENT_CREATED)»
			«ENDIF»
			«entity.generateTestVisitorEvent(testMethodName, true)»
			«entity.buildServiceCreateFromDTO»
			«buildEntityManagerFlush()»
			«entity.generatePublishedEventVerify(EVENT_CREATED)»
			«entity.generateTestVisitorEvent(testMethodName, entity.getEntityFieldName, false)»
			«entity.buildEntityToDTOAsActual»
			
			«IF !rulesFormOnCreate.empty»
			// Begin applying RuleFormOnCreate 
			«rulesFormOnCreate.map[generateRuleFormOnCreate(imports, 'caixa')].join»
			// End applying RuleFormOnCreate 
			«ENDIF»
			
			«entity.buildEntityCheckActualWithDTO»
		}
		'''
	}
	
	def CharSequence generateCreateTest2(Entity entity) {
		
		entity.slots.filter[it.isEntity].forEach[it.asEntity.resolveEntityImports(entity)]
		val rulesFormOnCreate = entity.rulesFormOnCreate
		val imports = entity.imports
		
		val testMethodName = 'testCreateWithOnlyRecairedFields'
		
		'''
		
		@Test
		public void «testMethodName»() throws Exception {
			«entity.buildNewEntityDTOVar»
			
			«entity.generateSettersOnlyRequiredSlotsForDTO»
			«IF entity.hasPublishEntityEvents»
			«entity.generatePublishedEventDoAnswer(EVENT_CREATED)»
			«ENDIF»
			«entity.generateTestVisitorEvent(testMethodName, true)»
			«entity.buildServiceCreateFromDTO»
			«buildEntityManagerFlush»
			«entity.generatePublishedEventVerify(EVENT_CREATED)»
			«entity.generateTestVisitorEvent(testMethodName, entity.getEntityFieldName, false)»
			«entity.buildEntityToDTOAsActual»
			
			«IF !rulesFormOnCreate.empty»
			// Begin applying RuleFormOnCreate 
			«rulesFormOnCreate.map[generateRuleFormOnCreate(imports, 'caixa')].join»
			// End applying RuleFormOnCreate 
			«ENDIF»
			
			«entity.buildEntityCheckActualWithDTOOnlyRequiredSlots»
		}
		'''
	}
	
	def CharSequence generateUpdateTest2(Entity entity) {
		
		val fieldName = entity.fieldName
		val id = entity.id
		
		entity.slots.filter[it.isEntity].forEach[it.asEntity.resolveEntityImports(entity)]
		
		val testMethodName = 'testUpdateWithOnlyRecairedFields'
		
		'''
		
		@Test
		public void «testMethodName»() throws Exception {
			«entity.buildNewOldEntityVar»
			«entity.buildGetEntityIdVarFromOldVar»
					
			«entity.buildNewEntityDTOVar»
			«fieldName».«id.buildMethodSet('id')»;
			
			«entity.generateSettersOnlyRequiredSlotsForDTO(#[id])»
			«IF entity.hasPublishEntityEvents»
			«entity.generatePublishedEventDoAnswer(EVENT_UPDATED)»
			«ENDIF»
			«entity.generateTestVisitorEvent(testMethodName, true)»
			«entity.buildServiceUpdateFromDTO»
			«buildEntityManagerFlush»
			«entity.generatePublishedEventVerify(EVENT_UPDATED)»
			«entity.generateTestVisitorEvent(testMethodName, entity.getEntityFieldName, false)»
			
			«entity.buildEntityToDTOAsActual»
			
			«entity.buildEntityCheckActualWithDTOOnlyRequiredSlots»
		}
		'''
	}
	
	def CharSequence generateUpdateTest1(Entity entity) {
		
		val fieldName = entity.fieldName
		val id = entity.id
		
		entity.slots.filter[it.isEntity].forEach[it.asEntity.resolveEntityImports(entity)]
		
		val testMethodName = 'testUpdateWithAllFields'
		
		'''
		
		@Test
		public void «testMethodName»() throws Exception {
			«entity.buildNewOldEntityVar»
			«entity.buildGetEntityIdVarFromOldVar»
					
			«entity.buildNewEntityDTOVar»
			«fieldName».«id.buildMethodSet('id')»;
			
			«entity.generateSettersForDTO(#[id])»
			«IF entity.hasPublishEntityEvents»
			«entity.generatePublishedEventDoAnswer(EVENT_UPDATED)»
			«ENDIF»
			«entity.generateTestVisitorEvent(testMethodName, true)»
			«entity.buildServiceUpdateFromDTO»
			«buildEntityManagerFlush»
			«entity.generatePublishedEventVerify(EVENT_UPDATED)»
			«entity.generateTestVisitorEvent(testMethodName, entity.getEntityFieldName, false)»
			
			«entity.buildEntityToDTOAsActual»
			
			«entity.buildEntityCheckActualWithDTO»
		}
		'''
	}
	
	def CharSequence generateListFilterAutoCompleteTests(Entity entity) {
		
		'''
		«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteTest].join»
		'''
	}
	
	def CharSequence generateFKAutoCompleteTests(Iterable<Slot> slots) {
		
		'''
		«slots.map[generateFKAutoCompleteTest].join»
		'''
	}
	
	def CharSequence generateAutoCompleteTests(Entity entity) {
		val firstAutocompleteKeySlot = entity.slots.filter[it.isAutoCompleteKey].head
		val size = 33;
		val resultSize = 1;
		
		val testMethodName = 'testAutoComplete'
		val fieldName = firstAutocompleteKeySlot.fieldName
		val subject = fieldName + 'ListFilter'
		
		'''
		@Test
		public void «testMethodName»() {
			«generateCallResetNextDate»
						
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateGetRandomItemsOf(resultSize)»
			
			«firstAutocompleteKeySlot.generateListFilterToSlot»
			«entity.generateTestVisitorEvent(testMethodName, subject, true)»
			«firstAutocompleteKeySlot.generateCallAutoComplete»
			«entity.generateTestVisitorEvent(testMethodName, 'result', false)»
			
			«firstAutocompleteKeySlot.generateAssertThatAutoComplete(resultSize)»
		}
		
		'''
	}
	
	def CharSequence generateFields(Entity entity, List<Slot> fkSlotsDistinct) {
		entity.addImport('import javax.inject.Inject;')
		
		'''
		
		@Inject
		protected «entity.toServiceName» «entity.toServiceName.toFirstLower»;
		
		@Inject
		protected «entity.toDTOConverterName» «entity.toDTOConverterName.toFirstLower»;
		
		@Inject
		protected «entity.toRepositoryName» «entity.toRepositoryName.toFirstLower»;
		«IF !fkSlotsDistinct.isEmpty»
		«fkSlotsDistinct.map[generateExtraFieldToInject].join»
		«ENDIF»
		
		«entity.generateMockEventPublisherField»
		'''
	}
	
	def CharSequence generateExtraFieldToInject(Slot slot) {
		val ownerEntity = slot.ownerEntity
		val entity = slot.asEntity
		
		ownerEntity.addImport(slot.resolveSlotRepositoryImport)
		
		val repsitoryName = entity.toRepositoryName
		
		'''
		
		@Inject
		protected «repsitoryName» «repsitoryName.toFirstLower»;
		'''
	}
	
	def CharSequence generateTestConfiguration(Entity entity) {
		entity.addImport('import org.springframework.boot.test.context.TestConfiguration;')
		entity.addImport('import org.springframework.context.annotation.Bean;')
		
		'''
		@TestConfiguration
		static class «entity.toServiceTestConfigurationName» {
			
			@Bean
			public «entity.toEntityListFilterPredicateName» «entity.toEntityListFilterPredicateName.toFirstLower»() {
				return new «entity.toEntityListFilterPredicateImplName»();
			}
			
			@Bean
			public «entity.toServiceName» «entity.toServiceName.toFirstLower»() {
				return new «entity.toServiceImplName»();
			}
			
			@Bean
			public «entity.toDTOConverterName» «entity.toDTOConverterName.toFirstLower»() {
				return new «entity.toDTOConverterName»();
			}
			
		}
		'''
	}
	
	
	def CharSequence generateTestAnnotations(Entity entity) {
		
		entity.addImport('import org.junit.runner.RunWith;')
		entity.addImport('import org.springframework.test.context.junit4.SpringRunner;')
		
		'''
		@RunWith(SpringRunner.class)
		'''
		
	}
	
	
	
}