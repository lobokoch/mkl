package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	StringConcatenationExt imports
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateService]
	}
	
	def generateService(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebServiceName + '.ts'
		generateFile(entityFile, entity.doGenerateEntityWebService)
	}
	
	def CharSequence doGenerateEntityWebService(Entity entity) {
		imports = new StringConcatenationExt()
		entity.initializeImports()
		
		// val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val varName = dtoName.toFirstLower
		val serviceName = entity.toEntityWebServiceClassName
		val entitySumFieldsClassName = entity.toEntitySumFieldsName
		
		val slots = entity.slots
		val slotsListFilter = slots.filter[hasListFilter]
		
		imports.add('''import { «dtoName» } from './«entity.toEntityWebModelName»';''')
		imports.add('''import { «entity.toAutoCompleteName» } from './«entity.toEntityWebModelName»';''')
		slots.filter[it.isEntity].forEach[
			imports.add('''import { «it.asEntity.toDtoName» } from './«entity.toEntityWebModelNameWithPah(it)»';''')
		]
		
		imports.add('''import { «entity.toEntityListFilterClassName» } from './«entity.toEntityWebModelName»';''')
		
		slotsListFilter.filter[isListFilterMany].forEach[
			imports.add('''import { «it.toAutoCompleteDTOName» } from './«entity.toEntityWebModelName»';''')
		]
		
		if (entity.hasSumFields) {
			imports.add('''import { «entitySumFieldsClassName» } from './«entity.toEntityWebModelName»';''')
		}
		
		
		val body = '''
		
		@Injectable()
		export class «serviceName» {
			
			// TODO: Provisório
			url = 'http://localhost:9101/entities/«varName»';
			
			constructor(private http: Http) { }
			
			// TODO: Provisório
			private getHeaders(): Headers {
				const headers = new Headers();
			    
			    headers.append('Content-Type', 'application/json');
			    return headers;
			}
			
			create(«varName»: «dtoName»): Promise<«dtoName»> {
				const headers = this.getHeaders();    
			
			    return this.http.post(this.url, JSON.stringify(«varName»), { headers })
			    .toPromise()
			    .then(response => {
			      const created = response.json() as «dtoName»;
			      «IF entity.hasEntitySlots»this.adjustNullEntitySlots([created]);«ENDIF»
			      «IF entity.hasDate»this.adjustEntityDates([created]);«ENDIF»
			      return created;
			    });
			}
			
			update(«varName»: «dtoName»): Promise<«dtoName»> {
			    const headers = this.getHeaders();
			
			    return this.http.put(`${this.url}/${«varName».«entity.id.fieldName»}`, JSON.stringify(«varName»), { headers })
			    .toPromise()
			    .then(response => {
			      const updated = response.json() as «dtoName»;
			      «IF entity.hasEntitySlots»this.adjustNullEntitySlots([updated]);«ENDIF»
			      «IF entity.hasDate»this.adjustEntityDates([updated]);«ENDIF»
			      return updated;
			    });
			}
			
			delete(id: string): Promise<void> {
			    return this.http.delete(`${this.url}/${id}`)
			    .toPromise()
			    .then(() => null);
			}
			
			retrieve(id: string): Promise<«dtoName»> {
			    const headers = this.getHeaders();
			    return this.http.get(`${this.url}/${id}`, { headers })
			    .toPromise()
			    .then(response => {
			      const «varName» = response.json() as «dtoName»;
			      «IF entity.hasEntitySlots»this.adjustNullEntitySlots([«varName»]);«ENDIF»
			      «IF entity.hasDate»this.adjustEntityDates([«varName»]);«ENDIF»
			      return «varName»;
			    });
			}
			
			«IF entity.hasDate»
			private adjustEntityDates(entityList: «dtoName»[]) {
				entityList.forEach(«varName» => {
				      «entity.slots.filter[it.isDate].map[it |
				      '''
				      if («varName».«it.fieldName») {
				        «varName».«it.fieldName» = moment(«varName».«it.fieldName», 'YYYY-MM-DD').toDate();
				      }
				      	
				      '''
				      ].join('\r\n')»
				});
			}
			«ENDIF»
			
			«IF entity.hasEntitySlots»
			private adjustNullEntitySlots(entityList: «dtoName»[]) {
				entityList.forEach(«varName» => {
				      «entity.slots.filter[it.isEntity].map[it |
				      '''
				      if (!«varName».«it.fieldName») {
				        «varName».«it.fieldName» = new «it.asEntity.toDtoName»();
				      }
				      	
				      '''
				      ].join('\r\n')»
				});
			}
			«ENDIF»
			
			autoComplete(query: string): Promise<«entity.toAutoCompleteName»[]> {
			    const headers = this.getHeaders();
			
			    const searchParams = new URLSearchParams();
			    searchParams.set('query', query);
			
			    return this.http.get(`${this.url}/autoComplete`, { headers, search: searchParams })
			      .toPromise()
			      .then(response => {
			        const result = response.json() as «entity.toAutoCompleteName»[];
			        return result;
			      });
			
			}
			
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			
			«varName»List(«varName»ListFilter: «dtoName»ListFilter): Promise<any> {
			    const headers = this.getHeaders();
			
			    const searchParams = this.mountAndGetSearchParams(«varName»ListFilter);
			
			    return this.http.get(this.url, { headers, search: searchParams })
			      .toPromise()
			      .then(response => {
			        const data = response.json();
			        const items = data.content; /* array of «dtoName» */
			        const totalElements = data.totalElements;
			
			        «IF entity.hasEntitySlots»this.adjustNullEntitySlots(items);«ENDIF»
			        «IF entity.hasDate»this.adjustEntityDates(items);«ENDIF»
			
			        const result = {
			          items,
			          totalElements
			        };
			
			        return result;
			      })
			      .catch(error => {
			        console.log(`Error in «varName»PagarList: ${error}`);
			      });
			}
			
			«IF entity.hasSumFields»
			
			get«entitySumFieldsClassName»(«entity.toEntityListFilterName»: «entity.toEntityListFilterClassName»): Promise<«entitySumFieldsClassName»> {
			    const headers = this.getHeaders();
			    
				const searchParams = this.mountAndGetSearchParams(«entity.toEntityListFilterName»);
				return this.http.get(`${this.url}/«entitySumFieldsClassName.toFirstLower»`, { headers, search: searchParams })
				  .toPromise()
				  .then(response => {
				    const result = response.json();
				    return result;
				  })
				  .catch(error => {
				    console.log(`Error in get«entitySumFieldsClassName»: ${error}`);
				  });
			}
			«ENDIF»
			
			mountAndGetSearchParams(«VAR_FILTER»: «dtoName»ListFilter): URLSearchParams {
			    const params = new URLSearchParams();
			    if («VAR_FILTER».pageNumber) {
			      params.set('page', «VAR_FILTER».pageNumber.toString());
			    }
			
			    if («VAR_FILTER».pageSize) {
			      params.set('size', «VAR_FILTER».pageSize.toString());
			    }
				
				«entity.slots.filter[it.hasListFilter].generateSlotsFilters»
			
			    // Sort
			    if («VAR_FILTER».sortField) {
			      // search/nameStartsWith?name=K&sort=name,desc
			      const sortField = «VAR_FILTER».sortField;
			      const sortValue = `${sortField.field},${sortField.order > 0 ? 'asc' : 'desc'}`;
			      params.set('sort', sortValue);
			    }
			
			    return params;
			  }
			
			dateToStr(data: Date): string {
			    return moment(data).format('YYYY-MM-DD');
			}
			
			/*** TODO: avaliar se vai ser feito isso.
			replicate«dtoName»(id: string, groupId: string, quantity: number): Promise<boolean> {
			    const headers = this.getHeaders();
			
			    const payload = new Replicate«dtoName»Payload(id, quantity, groupId);
			    return this.http.post(`${this.url}/replicate«dtoName»`, JSON.stringify(payload), { headers } )
			    .toPromise()
			    .then(response => {
			      return response.json() === true;
			    });
			}
				
			getTotais«VAR_FILTER»«dtoName»(«VAR_FILTER»: «dtoName»rListFilter): Promise<Totais«VAR_FILTER»«dtoName»> {
			    const headers = this.getHeaders();
			
			    const searchParams = this.mountAndGetSearchParams(«VAR_FILTER»);
			    return this.http.get(`${this.url}/getTotais«VAR_FILTER»«dtoName»`, { headers, search: searchParams })
			    .toPromise()
			    .then(response => {
			      const result = response.json() as Totais«VAR_FILTER»«dtoName»;
			      return result;
			    });
			}
			*/
		}
		
		'''
		
		val source = imports.ln.toString + body
		source
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		'''
		
		«autoComplateName»(query: string): Promise<any> {
		    const headers = this.getHeaders();
		
		    const searchParams = new URLSearchParams();
		    searchParams.set('query', query);
		
		    return this.http.get(`${this.url}/«autoComplateName»`, { headers, search: searchParams })
		      .toPromise()
		      .then(response => {
		        const result = response.json() as «autoComplateName.toFirstUpper»[];
		        return result;
		      });
		
		}
		'''
	}
	
	def CharSequence generateSlotsFilters(Iterable<Slot> slots) {
		'''
		«slots.map[generateSlotFilter].join('\r\n')»
		'''
	}
	
	def CharSequence generateSlotFilter(Slot slot) {
		val isNotNull = slot.isNotNull
			
		val isNull = slot.isNull
			
		val isMany = isMany(slot)
		
		val isBetween = slot.isBetween 
		var fieldName = '<unknown>'
		
		'''
		«IF isMany»
		// «fieldName = slot.fieldName»
		if («VAR_FILTER».«fieldName») {
			const «fieldName» = «VAR_FILTER».«fieldName».map(item => item.«fieldName»).join(',');
			params.set('«fieldName»', «fieldName»);
		}
		«ELSEIF isNotNull && isNull»
		// «fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		
		// «fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper»
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		«ELSEIF isNotNull»
		// «fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		«ELSEIF isNull»
		// «fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper»
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		«ELSEIF isBetween»
		// «fieldName = slot.fieldName + BETWEEN_FROM»
		if («VAR_FILTER».«fieldName») {
		«IF slot.isDate»
			const value = this.dateToStr(«VAR_FILTER».«fieldName»);
		«ELSE»
			const value = «VAR_FILTER».«fieldName»;
		«ENDIF»
			params.set('«fieldName»', value);
		}
		
		// «fieldName = slot.fieldName + BETWEEN_TO»
		if («VAR_FILTER».«fieldName») {
		«IF slot.isDate»
			const value = this.dateToStr(«VAR_FILTER».«fieldName»);
		«ELSE»
			const value = «VAR_FILTER».«fieldName»;
		«ENDIF»
			params.set('«fieldName»', value);
		}
		«ENDIF»
		'''
	}
	
	def void initializeImports(Entity entity) {
		imports.add('''
		import { Http, Headers, URLSearchParams } from '@angular/http';
		import { Injectable } from '@angular/core';
		import * as moment from 'moment';
		import { Observable } from 'rxjs';
		''')
	}
	
}