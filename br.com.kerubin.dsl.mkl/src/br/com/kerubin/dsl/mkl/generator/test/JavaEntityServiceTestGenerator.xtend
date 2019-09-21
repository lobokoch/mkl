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