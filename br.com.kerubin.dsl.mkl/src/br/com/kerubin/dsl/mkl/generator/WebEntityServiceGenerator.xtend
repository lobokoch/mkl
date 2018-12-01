package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.BooleanType
import br.com.kerubin.dsl.mkl.model.ByteType
import br.com.kerubin.dsl.mkl.model.DateTimeType
import br.com.kerubin.dsl.mkl.model.DateType
import br.com.kerubin.dsl.mkl.model.DoubleType
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FilterOperatorEnum
import br.com.kerubin.dsl.mkl.model.IntegerType
import br.com.kerubin.dsl.mkl.model.MoneyType
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.StringType
import br.com.kerubin.dsl.mkl.model.TimeType
import br.com.kerubin.dsl.mkl.model.UUIDType
import br.com.kerubin.dsl.mkl.util.StringConcatenationExt

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	private static val VAR_FILTER = 'filter'
	
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
		
		val webName = entity.toWebName
		val dtoName = entity.toDtoName
		val varName = dtoName.toFirstLower
		val serviceName = entity.toWebEntityServiceName
		
		imports.add('''import { «dtoName» } from './../model/«webName»-model';''')
		entity.slots.filter[it.isEntity].forEach[
			imports.add('''import { «it.asEntity.toDtoName» } from './../model/«it.asEntity.toWebName»-model';''')
		]
		
		val body = '''
		
		@Injectable()
		export class «serviceName» {
			
			// TODO: Provisório
			url = 'http://localhost:9101/entities/«varName»';
			
			constructor(private http: Http) { }
			
			// TODO: Provisório
			private getHeaders(): Headers {
			    const headers = this.getHeaders();
			    headers.append('Content-Type', 'application/json');
			    return headers;
			}
			
			create(«varName»: «dtoName»): Promise<«dtoName»> {
			    const headers = new Headers();
			
			    return this.http.post(this.url, JSON.stringify(«varName»), { headers })
			    .toPromise()
			    .then(response => {
			      const created = response.json() as «dtoName»;
			      «IF entity.hasEntitySlots»adjustNullEntitySlots([created]);«ENDIF»
			      «IF entity.hasDate»adjustEntityDates([created]);«ENDIF»
			      return created;
			    });
			}
			
			update(«varName»: «dtoName»): Promise<«dtoName»> {
			    const headers = new Headers();
			
			    return this.http.put(`${this.url}/${«varName».«entity.id.fieldName»}`, JSON.stringify(«varName»), { headers })
			    .toPromise()
			    .then(response => {
			      const updated = response.json() as «dtoName»;
			      «IF entity.hasEntitySlots»adjustNullEntitySlots([updated]);«ENDIF»
			      «IF entity.hasDate»adjustEntityDates([updated]);«ENDIF»
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
			      «IF entity.hasEntitySlots»adjustNullEntitySlots([«varName»]);«ENDIF»
			      «IF entity.hasDate»adjustEntityDates([«varName»]);«ENDIF»
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
			
			autoComplete(query: string): Promise<any> {
			    const headers = this.getHeaders();
			
			    const searchParams = new URLSearchParams();
			    searchParams.set('query', query);
			
			    return this.http.get(`${this.url}/autoComplete`, { headers, search: searchParams })
			      .toPromise()
			      .then(response => {
			        const resultArray = response.json() as «dtoName»AutoComplete[];
			        return resultArray;
			      });
			
			}
			
			«varName»List(«varName»ListFilter: «dtoName»ListFilter): Promise<any> {
			    const headers = this.getHeaders();
			
			    const searchParams = this.mountAndGetSearchParams(«varName»ListFilter);
			
			    return this.http.get(this.url, { headers, search: searchParams })
			      .toPromise()
			      .then(response => {
			        const data = response.json();
			        const items = data.content; /* array of «dtoName» */
			        const totalElements = data.totalElements;
			
			        «IF entity.hasEntitySlots»adjustNullEntitySlots(items);«ENDIF»
			        «IF entity.hasDate»adjustEntityDates(items);«ENDIF»
			
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
			    if (filtro.sortField) {
			      // search/nameStartsWith?name=K&sort=name,desc
			      const sortField = filtro.sortField;
			      const sortValue = `${sortField.field},${sortField.order === 0 ? 'asc' : 'desc'}`;
			      params.set('sort', sortValue);
			    }
			
			    return params;
			  }
			
		}
			
			
			
		dateToStr(data: Date): string {
		    return moment(data).format('YYYY-MM-DD');
		}
		
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
		
		'''
		
		val source = imports.ln.toString + body
		source
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
		«fieldName = slot.fieldName»
		if («VAR_FILTER».«fieldName») {
			const «fieldName» = «VAR_FILTER».«fieldName».map(item => item.«fieldName»).join(',');
			params.set('«fieldName»', «fieldName»);
		}
		«ELSEIF isNotNull && isNull»
		«fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»
		
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		
		«fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper»
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		«ELSEIF isNotNull»
		«fieldName = slot.fieldName + FilterOperatorEnum.IS_NOT_NULL.getName.toFirstUpper»
				
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		«ELSEIF isNull»
		«fieldName = slot.fieldName + FilterOperatorEnum.IS_NULL.getName.toFirstUpper»
		if («VAR_FILTER».«fieldName») {
			const value = «VAR_FILTER».«fieldName» ? 'true' : 'false';
			params.set('«fieldName»', value);
		}
		«ELSEIF isBetween»
		«fieldName = slot.fieldName + BETWEEN_FROM»
		if («VAR_FILTER».«fieldName») {
		«IF slot.isDate»
			const value = this.dateToStr(«VAR_FILTER».«fieldName»);
		«ELSE»
			const value = «VAR_FILTER».«fieldName»;
		«ENDIF»
			params.set('«fieldName»', value);
		}
		
		«fieldName = slot.fieldName + BETWEEN_TO»
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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	def CharSequence mountAutoCompleteSuggestionsVar(Slot slot) {
		val entity = slot.asEntity
		'''
		«slot.webAutoCompleteSuggestions»: «entity.toDtoName»[];
		'''
	}
	
	def CharSequence mountAutoComplete(Slot slot) {
		val entity = slot.asEntity
		val serviceName = entity.toWebEntityServiceName
		
		'''
		«entity.toEntityAutoCompleteName»(event) {
		    const query = event.query;
		    this.«serviceName.toFirstLower»
		      .autoComplete(query)
		      .then((result) => {
		        this.«slot.webAutoCompleteSuggestions» = result as «entity.toDtoName»[];
		      })
		      .catch(error => {
		        this.showError('Erro ao buscar Fornecedor com o termo: ' + query);
		      });
		}
		'''
	}
	
	def CharSequence mountServiceConstructorInject(Slot slot) {
		val serviceName = slot.asEntity.toWebEntityServiceName
		'''
		private «serviceName.toFirstLower»: «serviceName»,
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
	
	def CharSequence generateEntityReplication(Entity entity) {
		'''
		
		<!-- Begin Agrupador -->
		<div class="ui-g-12" *ngIf="«entity.fieldName».«entity.id.fieldName» != null" style="margin: 0 auto">
		      <div class="ui-g-12 ui-md-4 ui-fluid">
		        <label>Agrupador</label>
		        <input [(ngModel)]="«entity.fieldName».agrupador" minlength="3" pInputText type="text" name="agrupador" ngModel>
		      </div>
		
		      <div class="ui-g-12 ui-md-2 ui-fluid">
		        <label>Quantidade</label>
		        <p-spinner ngModel name="«entity.entityReplicationQuantity»" size="10" [(ngModel)]="«entity.entityReplicationQuantity»" [min]="1" [max]="100"></p-spinner>
		      </div>
		
		      <div class="ui-g-12 ui-md-2 ui-fluid centro-pai" >
		        <div class="ui-g-12 ui-md-2 centro-filho">
		          <button pButton (click)="«entity.entityReplicationMethod»" type="button" label="Replicar" class="ui-button-info"></button>
		        </div>
		      </div>
		</div>
		<!-- End Agrupador -->
		'''
	}
	
	def CharSequence generateButtons(Entity entity) {
		'''
		
		<div class="ui-g-12">
			<div class="ui-g-12 ui-md-4">
				<button [disabled]="!form1.valid" class="botao-margem-direita" pButton type="submit" label="Salvar"></button>
				<button pButton (click)="begin(form1)" type="button" label="Novo" class="botao-margem-direita ui-button-info"></button>
				<button pButton (click)="begin(form1)" type="button" label="Novo" class="botao-margem-direita ui-button-info"></button>
				<a routerLink="/«entity.toWebName»" pButton label="Pesquisar"></a>
			</div>
		</div>
		
		'''
	}
	
	def CharSequence generateEntityTitle(Entity entity) {
		'''
		<div>
			<h1>«entity.translationKey.transpationKeyFunc»</h1>
		</div>
		'''
	}
	
	def CharSequence generateEntityFields(Entity entity) {
		'''
		«entity.slots.map[generateField(entity)].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateField(Slot slot, Entity entity) {
		if (slot.isDTOFull) {
		}
		else if (slot.isDTOLookupResult) {
		}
		else if (slot.isEnum) { 
		}
		
		'''
		«IF slot.isToMany»
		slot.isToMany
		«ELSE»
		<div class="«slot.webClass»">
			<label>«slot.webLabel»</label>
			«slot.generateWebComponent»
		</div>
		«ENDIF»
		'''
	}
	
	def CharSequence generateWebComponent(Slot slot) {
		val builder = new StringConcatenationExt()
		builder.concat('<')
		slot.decoreWebComponent(builder)
		builder.concat(' />')
		
		slot.generateComponentMessages(builder)
		
		val result = builder.build
		result
	}
	
	def CharSequence generateComponentMessages(Slot slot, StringConcatenationExt builder) {
		if (!slot.optional) {
			builder.add('''<div class="invalid-message" *ngIf="«slot.fieldName».invalid && «slot.fieldName».dirty">Campo obrigatório.</div>''')
		}
	}
	
	def void decoreWebComponent(Slot slot, StringConcatenationExt builder) {
		slot.decorateWebComponentType(builder)
		slot.decorateWebComponentNgModel(builder)
		slot.decorateWebComponentName(builder)
		slot.decorateWebComponentRules(builder)
	}
	
	def void decorateWebComponentRules(Slot slot, StringConcatenationExt builder) {
		if (!slot.optional) {
			builder.concat(' required')
		}
		
		if (slot.UUID) {
			builder.concat(' readonly class="read-only"')
		}
	}
	
	def void decorateWebComponentName(Slot slot, StringConcatenationExt builder) {
			builder.concat(''' name="«slot.fieldName»"''')
	}
	
	def void decorateWebComponentNgModel(Slot slot, StringConcatenationExt builder) {
			builder.concat(''' ngModel [(ngModel)]="«slot.ownerEntity.fieldName».«slot.fieldName»"''')
	}
	
	def void decorateWebComponentType(Slot slot, StringConcatenationExt builder) {
		if (slot.isEntity) {
			val entity = slot.asEntity
			val fieldName = entity.slots.findFirst[it.autoCompleteResult]?.fieldName ?: entity.id.fieldName
			
			builder.concat('''p-autoComplete [forceSelection]="true" [suggestions]="«slot.webAutoCompleteSuggestions»" (completeMethod)="«slot.webAutoComplete»($event)" field="«fieldName»"''')
			return
		}
		else if (slot.isEnum){
			builder.concat('''p-dropdown [options]="«slot.webDropdownOptions»" placeholder="Selecione"''')
			return
		}
		
		// Is a basic type
		val basicType = slot.basicType
		
		if (basicType instanceof StringType) {
			val stringType = basicType as StringType
			// Must be a TextArea?
			if (stringType.length > 255) {
				builder.concat('textarea pInputTextarea rows="3"')			
			}
			else { // Input Text
				builder.concat('input type="text" pInputText')				
			}
		}
		else if (basicType instanceof IntegerType) {
			builder.concat('input type="text" pInputText')
		}
		else if (basicType instanceof DoubleType) {
			builder.concat('input type="text" pInputText')
		}
		else if (basicType instanceof MoneyType) {
			builder.concat('input currencyMask [options]="{prefix: \'\', thousands: \'.\', decimal: \',\', allowNegative: false}" placeholder="0,00"')
		}
		else if (basicType instanceof BooleanType) {
			builder.concat('p-inputSwitch')
		}
		else if (basicType instanceof DateType) {
			builder.concat('p-calendar dateFormat="dd/mm/yy"')
		}
		else if (basicType instanceof TimeType) {
			builder.concat('p-calendar dateFormat="hh:MM:ss"')
		}
		else if (basicType instanceof DateTimeType) {
			builder.concat('p-calendar dateFormat="dd/mm/yy hh:MM:ss"')
		}
		else if (basicType instanceof UUIDType) {
			builder.concat('input type="text" pInputText')
		}
		else if (basicType instanceof ByteType) {
			builder.concat('input type="text" pInputText')
		}
		
	}
	
	def CharSequence generateInputComponent(Slot slot) {
		val builder = new StringConcatenationExt()
		
		val result = builder.build
		result
	}
	
	
	
	def CharSequence generateGetters(Entity entity) {
		'''
		
		«entity.slots.map[generateGetter].join('\r\n')»
		'''
		
	}
	
	def CharSequence generateGetter(Slot slot) {
		
		'''
		«IF slot.isToMany»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO»[] {
		«ELSE»
		get «slot.name.toFirstUpper»(): «slot.toWebTypeDTO» {
		«ENDIF»
			return this.«slot.name.toFirstLower»;
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
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO»[]) {
		«ELSE»
		set «slot.name.toFirstUpper»(value: «slot.toWebTypeDTO») {
		«ENDIF»
			this.«slot.name.toFirstLower» = value;
		}
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