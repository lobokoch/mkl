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

class JavaEntityServiceTestGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.canGenerateTest].forEach[generateTest]
	}
	
	def generateTest(Entity entity) {
		val basePakage = getServerTestGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceTestName + '.java'
		generateFile(fileName, entity.generateEntityTest)
	}
	
	def CharSequence generateEntityTest(Entity entity) {
		
		entity.imports.clear
		//entity.addImport('import static br.com.kerubin.api.servicecore.util.CoreUtils.generateRandomString;')
		
		entity.resolveEntityImports
		
		val dependenciesSource = new StringBuilder() 
		
		entity.generateTestDependencies(dependenciesSource, new ArrayList())
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		«entity.generateTestAnnotations»
		public class «entity.toServiceTestName» extends «service.toServiceEntityBaseTestClassName» {
			
			«entity.generateIgnoredFieldsConstant»
			
			«entity.generateTestConfiguration»
			
			«entity.generateFields»
			
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
		val createTests = entity.generateCreateTest1
		createTests
	}
	
	def CharSequence generateUpdateTests(Entity entity) {
		val updateTest1 = entity.generateUpdateTest1
		updateTest1
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
		//val hasSomeListFilterMany = entity.slots.exists[it.isListFilterMany]
		val hasSort = entity.slots.exists[it.hasSort]
		
		if (hasSort) {
			entity.addImport('import java.util.Collections;')
			entity.addImport('import org.springframework.data.domain.Sort;')
		}
		
		entity.addImport('import java.util.List;')
		entity.addImport('import java.util.ArrayList;')
		entity.addImport('import java.util.stream.Collectors;')
		entity.addImport('import org.springframework.data.domain.Pageable;')
		entity.addImport('import org.springframework.data.domain.Page;')
		entity.addImport('import org.springframework.data.domain.PageRequest;')
		// entity.addImport('import static br.com.kerubin.api.servicecore.util.CoreUtils.getRandomItemsOf;')
		entity.addImport(service.importPageResult)
		
		var CharSequence test1 = ''
		var CharSequence test2 = ''
		
		if (entity.slots.exists[it.isListFilterMany]) {
			test1 = entity.generateListTest1
		}
		
		if (entity.slots.exists[it.hasSort]) {
			test2 = entity.generateListTest2
		}
		
		'''
		«test1»
		«test2»
		'''
	}
	
	def CharSequence generateListTest1(Entity entity) {
		
		val firstListFilterSlot = entity.slots.filter[it.isListFilterMany].head
		val size = 33;
		val resultSize = 7;
		
		'''
		
		@Test
		public void testList_FilteringBy«firstListFilterSlot.fieldName.toFirstUpper»() {
			«generateCallResetNextDate»
			
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateNewEntityListFilterVar»
			
			«entity.generateGetRandomItemsOf(resultSize)»
			
			«firstListFilterSlot?.generateAndSetListFilterToSlot»
			
			«generatePageableWithoutSort(0, size)»
			
			«entity.generateCallServiceList»
			
			«entity.generatePageContentMapToPageResult»
			
			«firstListFilterSlot?.assertThatSlotListFilterResultContent(resultSize)»
			
			«generateAssertThatPageResult(1, resultSize, resultSize)»
			
		}
		'''
	}
	
	def CharSequence generateListTest2(Entity entity) {
		val size = 10;
		val sortSlot = entity.slots.filter[it.hasSort].head
		
		'''
		
		@Test
		public void testList_SortingBy«sortSlot.fieldName.toFirstUpper»() {
			«generateCallResetNextDate»
			
			«entity.generateInicializeCreateDataForEntity(size)»
			
			«entity.generateNewEntityListFilterVar»
			
			«generatePageableAsc(0, size, sortSlot)»
			
			«entity.generateCallServiceList»
			
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
		
		'''
		
		@Test
		public void testRead1() {
			«entityName» expected«entityName» = new«entityName»();
			«entity.id.toJavaType» id = expected«entityName».«entity.id.getMethod2»;
			«name» expected = «varName»DTOConverter.convertEntityToDto(expected«entityName»);
			
			«entityName» read«entityName» = «varName»Service.read(id);
			«name» actual = «varName»DTOConverter.convertEntityToDto(read«entityName»);
			
			assertThat(actual).isEqualToComparingFieldByField(expected);
			
		}
		'''
	}
	
	def CharSequence generateDeleteTest1(Entity entity) {
		val entityName = entity.toEntityName
		val expected = 'expected'
		val idVar = 'id'
		
		'''
		
		@Test
		public void testDelete1() {
			«entityName» «expected» = new«entityName»();
			«entity.id.toJavaType» «idVar» = «expected».«entity.id.getMethod2»;
			
			«entity.generateEntityManagerFind»
			«expected.buildAssertThatIsNotNull»
			
			«entity.generateServiceDelete»
			
			«entity.generateEntityManagerFind»
			«expected.buildAssertThatIsNull»
		}
		'''
	}
	
	def CharSequence generateCreateTest1(Entity entity) {
		
		entity.slots.filter[it.isEntity].forEach[it.asEntity.resolveEntityImports(entity)]
		
		'''
		/**
		 * Explanation of this test:
		 * - Creates a new record setting all attributes
		 * - Check the results and orders for fields descricao, dataVencimento.
		 * */
		@Test
		public void testCreate1() throws Exception {
			«entity.buildNewEntityDTOVar»
			
			«entity.generateSettersForDTO»
			
			«entity.buildServiceCreateFromDTO»
			«buildEntityManagerFlush»
			
			«entity.buildEntityToDTOAsActual»
			
			«entity.buildEntityCheckActualWithDTO»
		}
		'''
	}
	
	def CharSequence generateUpdateTest1(Entity entity) {
		
		val fieldName = entity.fieldName
		val id = entity.id
		
		entity.slots.filter[it.isEntity].forEach[it.asEntity.resolveEntityImports(entity)]
		
		'''
		/**
		 * Explanation of this test:
		 * - Creates a new record setting all attributes
		 * - Check the results and orders for fields descricao, dataVencimento.
		 * */
		@Test
		public void testUpdate1() throws Exception {
			«entity.buildNewOldEntityVar»
			«entity.buildGetEntityIdVarFromOldVar»
					
			«entity.buildNewEntityDTOVar»
			«fieldName».«id.buildMethodSet('id')»;
			
			«entity.generateSettersForDTO(#[id])»
			
			«entity.buildServiceCreateFromDTO»
			«buildEntityManagerFlush»
			
			«entity.buildEntityToDTOAsActual»
			
			«entity.buildEntityCheckActualWithDTO»
		}
		'''
	}
	
	def CharSequence generateFields(Entity entity) {
		entity.addImport('import javax.inject.Inject;')
		entity.addImport('import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;')
		
		'''
		@Inject
		private TestEntityManager em;
		
		@Inject
		private «entity.toServiceName» «entity.toServiceName.toFirstLower»;
		
		@Inject
		private «entity.toDTOConverterName» «entity.toDTOConverterName.toFirstLower»;
		
		@Inject
		private «entity.toRepositoryName» «entity.toRepositoryName.toFirstLower»;
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